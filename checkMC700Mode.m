function t = checkMC700Mode()

global MC700BConnection

status = [];
debugflag = 0;

if(isempty(MC700BConnection))
    fprintf(1, 'mc700btelegraph: Making connnection...  ');
    timeout = 2;
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

    fprintf(MC700BConnection,  'getMode(%d)\n', i-1);
    mc700msg = fscanf(MC700BConnection);
    [vargs, err] = strparse(mc700msg);
    if(err > 0)
        status(i).mode = 'X';
        status(i).extcmd = 0;
    end;
    switch (unblank(vargs{1}))
        case {'V-Clamp', 'VC'} % voltage clamp
            t(i).mode = 'V';
        case {'I-Clamp', 'IC'}  % current clamp
            t(i).mode = 'I';
        case {'I = 0', 'I=0'}    % I = 0
            t(i).mode = '0';
        otherwise       % unknown
            t(i).mode = 'X';
    end
    if(debugflag)
        fprintf(1, '\nMode: %s\n', tmode);
    end;
end;
