function mc700bswitch(InputSelect, mode)
%
% simple function to switch the 700b amplifier through a command.
% NO check for errors.... help!
% 2/7/08
% 
% 8/14/08 - subtle changes:
% can call with inputselect as an array of "amplifiers", and mode with
% either a single mode for all amplifiers, or different modes for each
% ampilfier. 

[conn, err]  = MC700('open');
if(err)
    return;
end;

fprintf(conn,  'getNumDevices()');
ndev = getMC700(conn);
devicelist = eval(sprintf('[%s]', ndev)); % evaluate the device list

newmode = cell(size(InputSelect));
if(length(mode) ~= length(InputSelect)) % just apply the mode to all the inputs
    for i = 1:length(InputSelect)
        if(iscell(mode))
            newmode{i} = char(mode);
        else
            newmode{i} = mode;
        end;
    end;
else
    newmode = mode;
end;


for i = 1:length(InputSelect)
    thisdevice = InputSelect(i);
    if(iscell(newmode))
        thismode = char(newmode{i});
    else
        thismode = newmode(i);
    end;
    
    if(find(thisdevice == devicelist)) % make sure it is in the list...
        ndev = thisdevice - 1;
        switch(thismode)
            case {'V', 'VC', 'V-Clamp'}
                fprintf(conn, 'setMode(%d,VC)', ndev);
            case '0'
                fprintf(conn, 'setMode(%d,I=0)', ndev);
            case {'I', 'IC', 'I-Clamp'}
                fprintf(conn, 'setMode(%d,IC)', ndev);
            otherwise
                fprintf(1, 'Mode not recognized: %s\n', thismode);
        end;
        fprintf(conn, 'getMode(%d)\n', ndev); % read the mode

    thenewmode = getMC700(conn);

    else
        fprintf(1, 'Device %d not in list\n', thisdevice);
    end;
end;

MC700('close');


