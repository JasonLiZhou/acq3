function status = mc700btelegraph()
%
% telegraph wrapper for Lukes TCP
% requires using tcp_ip code from mathworks user support.
% Modified 8/1/08 to use Instrument Control Toolbox rather than pnet.
% we always open and close the connection with each call.
%
% return
% mode
% scaled_unit
% scaled_gain
% lpf_unit
% lpf (in lpf_unit)
%
global MC700BConnection HARDWARE
persistent gain1errorflag gain2errorflag lpf1errorflag lpf2errorflag

if(~exist('gain1errorflag', 'var')) % this flag controls the error report
    gain1errorflag = 0;
    gain2errorflag = 0;
    lpf1errorflag = 0;
    lpf2errorflag = 0;
end;


debugflag = 0;

if(isempty(MC700BConnection))
%    fprintf(1, 'mc700btelegraph: Making connnection...  ');
    %     timeout = 2;
    MC700BConnection = tcpip('localhost', 34567);

    try
        fopen(MC700BConnection);
    catch
        fprintf(1, 'unable to open TCP server\n');
        fprintf(1, 'Cannot Connect to Multiclamp TCP Server\n');
        status = [];
        return;
    end;
    %    fprintf(MC700BConnection, 'setreadtimeout',timeout);
%    fprintf(1, 'Connection successful\n');
end;

fprintf(MC700BConnection, 'getNumDevices()')
ndev = fscanf(MC700BConnection);
%u = find(ndev == 0);
%ndev(u) = ' '; % clean null strings.

devlist = eval(sprintf('[%s]', ndev)); % evaluate the device list
if(debugflag)
    fprintf(1, 'Devlist: %s\n', ndev);
    for i = devlist
        fprintf(1, 'device: %d\n', devlist(i));
    end;
end;



status = struct ('measure', 'gain', 'unit', 'scaled_unit');
for i = fliplr(devlist) % for each device, get the information
    fprintf(MC700BConnection, 'getPrimarySignalInfo(%d)\n', i-1);
    pause(0.01);
    mc700msg = fscanf(MC700BConnection);
    [vargs, err] = strparse(mc700msg);
    if(err == 0)
        status(i).measure = vargs{1};
        status(i).gain = vargs{2};
        status(i).unit = vargs{3};
        status(i).scaled_unit = ['V/' vargs{3}];
    end;
    if(debugflag)
        fprintf(1, 'Status = %d\n', status(i));
    end;

    fprintf(MC700BConnection,  'getMode(%d)\n', i-1);
    pause(0.01);
    mc700msg = fscanf(MC700BConnection);
    [vargs, err] = strparse(mc700msg);
    if(err > 0)
        status(i).mode = 'X';
        status(i).extcmd = 0;
    end;
    tmode = vargs{1};
    if(debugflag)
        fprintf(1, '\nMode: %s\n', tmode);
    end;

    %%%%  Use a DLL to read some other pareameteres....
    %%%%
    %    tgchan = mctgclient('start'); % also connect via Scott Molitor's DLL
    %    flag = mctgclient('select',tgchan(i));
    %    tg = mctgclient('read'); % and read the telegraph here.
    %    mctgclient('stop');
    %%%% end of dll call - all the rest is with tcpip
    %%%%

    %    status(i).extcmd = tg.extcmd;
    %    status(i).extcmd_unit = tg.extcmd_unit;
    %    status(i).mode = tg.mode;
    %
    % we leave this hard codeed because we cannot read it. You must be sure that
    % you have set the amp to the corerect gain settings to match. At some point
    % I will write something to test this when the program is started.

    switch(unblank(tmode))
        case 'VC'
            status(i).mode = 'V-Clamp';
            status(i).extcmd = HARDWARE.multiclamp.ExtCmd_VC(i);
            status(i).extcmd_unit = [HARDWARE.multiclamp.OutputUnitsVC '/V'];

        case 'I=0'
            status(i).mode = 'I = 0';
            status(i).extcmd = HARDWARE.multiclamp.ExtCmd_CC(i);
            status(i).extcmd_unit = [HARDWARE.multiclamp.OutputUnitsCC '/V'];
        case {'IC', 'C'}
            status(i).mode = 'I-Clamp';
            status(i).extcmd = HARDWARE.multiclamp.ExtCmd_CC(i);
            status(i).extcmd_unit = [HARDWARE.multiclamp.OutputUnitsCC '/V'];
    end;
    fprintf(MC700BConnection, 'getPrimarySignalGain(%d)\n', i-1);
    mc700bmsg = fscanf(MC700BConnection);
    [vargs, err] = strparse(mc700bmsg);
    if(err > 0)
        if(~gain1errorflag)
            fprintf(1, 'Unable to get Primary Signal Gain on MC700A amplifier: setting to 1\n');
            gain1errorflag = 1;
        end;
        status(i).scaled_gain = 1;
    end;
    status(i).scaled_gain = str2double(vargs{1});

    fprintf(MC700BConnection,  'getPrimarySignalLPF(%d)\n', i-1);
    mc700bmsg = fscanf(MC700BConnection);
    [vargs, err] = strparse(mc700bmsg);
    if(err > 0)
        if(~lpf1errorflag)
            fprintf(1, 'Unable to get Primary Signal LPF on MC700A amplifier: setting to 0\n');
            lpf1errorflag = 1;
        end;
        status(i).lpf = 0;
    end;
    status(i).lpf = str2double(vargs{1});
    status(i).lpf_unit='Hz';

    fprintf(MC700BConnection, 'getSecondarySignalGain(%d)\n', i-1);
    mc700bmsg = fscanf(MC700BConnection);
    [vargs, err] = strparse(mc700bmsg);
    if(str2double(vargs{1}) < 0.001 || err > 0)
        if(~gain2errorflag)
            fprintf(1, 'Unable to Secondary Signal Gain on MC700A amplifier: setting to 10\n');
            gain2errorflag = 1;
        end;
        status(i).scaled_gain2 = 10;
    else
        status(i).scaled_gain2 = str2double(vargs{1});
    end;

    fprintf(MC700BConnection, 'getSecondarySignalLPF(%d)\n', i-1);
    mc700bmsg = fscanf(MC700BConnection);
    [vargs, err] = strparse(mc700bmsg);
    if(str2double(vargs{1}) < 0.1 || err > 0)
        if(~lpf2errorflag)
            fprintf(1, 'Unable to get Secondary LPF on MC700A amplifier: setting to 0\n');
            lpf2errorflag = 1;
        end;
        status(i).lpf2 = 0;
    else
        status(i).lpf2 = str2double(vargs{1});
    end;
    status(i).lpf_unit2='Hz';

end;
fclose(MC700BConnection);
MC700BConnection = [];





