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

timeout = 2;
con = tcpip('127.0.0.1', 34567); % connect to the server
if(con == 0)
    fprintf(1, 'Cannot Connect to Multiclamp FTP Server\n');
    return;
end;
%fprintf(con,'setreadtimeout',2.0)
fopen(con);
fprintf(con,  'getNumDevices()');
ndev = fscanf(con);
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
        thismode = char(newmode{i})
    else
        thismode = newmode(i);
    end;
    
    if(find(thisdevice == devicelist)) % make sure it is in the list...
        ndev = thisdevice - 1;
        switch(thismode)
            case {'V', 'VC', 'V-Clamp'}
                fprintf(con, 'setMode(%d,VC)\n', ndev);
            case '0'
                fprintf(con, 'setMode(%d,I=0)\n', ndev);
            case {'I', 'IC', 'I-Clamp'}
                fprintf(con, 'setMode(%d,IC)\n', ndev);
            otherwise
                fprintf(1, 'Mode not recognized: %s\n', thismode);
        end;
        fprintf(con, 'getMode(%d)\n', ndev); % read the mode
        thenewmode = fscanf(con);

    else
        fprintf(1, 'Device %d not in list\n', thisdevice);
    end;
end;

fclose(con);
delete(con);
clear con
