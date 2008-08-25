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
global MC700BConnection
status = [];
debugflag = 0;

if(isempty(MC700BConnection))
    fprintf(1, 'mc700btelegraph: Making connnection...  ');
    timeout = 2;
    MC700BConnection = tcpip('localhost', 34567);
    if(MC700BConnection == 0)
        fprintf(1, 'Cannot Connect to Multiclamp TCP Server\n');
        return;
    end;
    fopen(MC700BConnection);
    %    fprintf(MC700BConnection, 'setreadtimeout',timeout);
    fprintf(1, 'Connection successful\n');
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

for i = devlist % for each device, get the information
    fprintf(MC700BConnection, 'getPrimarySignalInfo(%d)\n', i-1);
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
    
    switch(unblank(tmode))
        case 'VC'
            status(i).mode = 'V-Clamp';
            status(i).extcmd = 20;
            status(i).extcmd_unit = 'mV/V';
        case 'I=0'
            status(i).mode = 'I = 0';
            status(i).extcmd = 400;
            status(i).extcmd_unit = 'pA/V';
        case {'IC', 'C'}
            status(i).mode = 'I-Clamp';
            status(i).extcmd = 400; % hard coded because we can't read it ... 
            status(i).extcmd_unit = 'pA/V';
    end;
    fprintf(MC700BConnection, 'getPrimarySignalGain(%d)\n', i-1);
    mc700bmsg = fscanf(MC700BConnection);
    [vargs, err] = strparse(mc700bmsg);
    if(err > 0)
        fprintf(1, 'Unable to read gain\n');
        status(i).scaled_gain = 1;
    end;
    status(i).scaled_gain = str2double(vargs{1});
        
    fprintf(MC700BConnection,  'getPrimarySignalLPF(%d)\n', i-1);
    mc700bmsg = fscanf(MC700BConnection);
    [vargs, err] = strparse(mc700bmsg);
    if(err > 0)
        fprintf(1, 'Unable to read gain\n');
        status(i).lpf = 0;
    end;
    status(i).lpf = str2double(vargs{1});
    status(i).lpf_unit='Hz';

    fprintf(MC700BConnection, 'getSecondarySignalGain(%d)\n', i-1);
    mc700bmsg = fscanf(MC700BConnection);
    [vargs, err] = strparse(mc700bmsg);
    if(err > 0)
        fprintf(1, 'Unable to read gain\n');
        status(i).scaled_gain2 = 1;
    end;
    status(i).scaled_gain2 = str2double(vargs{1});

       fprintf(MC700BConnection, 'getSecondarySignalLPF(%d)\n', i-1);
    mc700bmsg = fscanf(MC700BConnection);
    [vargs, err] = strparse(mc700bmsg);
    if(err > 0)
        fprintf(1, 'Unable to read gain\n');
        status(i).lpf = 0;
    end;
    status(i).lpf2 = str2double(vargs{1});
    status(i).lpf_unit2='Hz';

end;



function [res, err] = strparse(inpstring)
err = 0;
[serr, arglist] = strtok(inpstring, ',');
if(str2double(serr) ~= 1)
    err = 1;
    return;
end;
i = 1;
while(~isempty(arglist))
    [res{i} arglist] = strtok(arglist, ',');
    i = i + 1;
end;
