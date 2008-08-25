function varargout = g(sfilename)
% g: get a stimulus file from disk
% ***CMD***
% The line above specifies this file as avaialable at the command line in
% acq3

% Usage
%     g [filename] gets and loads the sfile (and dfile if included) structures
%     from the selected file
%     If no filename is specified, a browser window is provided to select a file.

% 7/10/2000 - get a stimulus file from disk.
% Paul B. Manis   pmanis@med.unc.edu
% returns the loaded sfile structure in global variable SFILE.
% If you call without a filename on the command line, then
% this routine will use uigetfile to do the file access
% if there is an output argument, the data is returned there rather than in
% the global variable stim (9/11/2000 P. Manis)
% if there is an acq file stored in the stim file, then use it (makes AcqFile empty
% so when we save it the current acq structure is saved).
% 3/18/08 cleaned up
% pmanis
global STIM DFILE CONFIG ONLINE IN_ACQ DISPCTL DEVICE_ID
debugme = 0;

QueMessage(' ', 1);
if(IN_ACQ)
    QueMessage('Already in acquisition: cannot change protocols', 1);
    return;
end;

onl = [];
if(nargout > 0)
    for i = 1:nargout
        varargout{i} = []; % initialize the outputs if present
    end;
end;
% load a protocol from the disk
fullstmpath = slash4OS([append_backslash(CONFIG.BasePath.v) CONFIG.StmPath.v]);
if(exist(fullstmpath, 'dir') == 7)
    wd = cd(fullstmpath);
else
    QueMessage(sprintf('g: Configuration StimPath %s invalid', fullstmpath), 1);
    return;
end;

if(nargin == 0)
    [stimname, stimpath] = uigetfile('*.mat','Load Stimulus File');
    if(stimname == 0)
        cd(wd);
        return;
    end;
    sfilename=fullfile(stimpath, stimname);
end;
sfilename=unblank(sfilename);
[path file ext] = fileparts(sfilename); % if filename still missing extension, add the default
if(isempty(ext))
    sfilename = [sfilename '.mat'];
end;
fid = fopen(sfilename, 'r');
if(fid == -1)
    QueMessage(sprintf('File %s not found? ', sfilename), 1);
    cd(wd);
    return;
end;
fclose(fid);
a = load(sfilename);
sf=a.STIM;
x = fieldnames(a);
if(debugme)
    fprintf(1, 'Fieldnames in Stim file:\n');
    for i = 1:length(x)
        fprintf(1, '%s, ', char(x{i}));
    end;
    fprintf(1, '\n');
end;

df=[];
if(strmatch('DFILE', x, 'exact')) % indicates that an acquisition block was stored with the stimulus
    df = a.DFILE;
    sf.AcqFile.v = []; % force internal (although should not be necessary)
end;
if(strmatch('ONLINE', x, 'exact'))
    onl = a.ONLINE;
end;
if(strmatch('DISPCTL', x, 'exact'))
    displaycontrol = a.DISPCTL;
end;

cd(wd);
if(chkfile(sf))
    return;
end;
if(debugme)
    fprintf(1, 'Checking configuration and modes\n');
end;

% before we put the data out, we need to verify that the requested data
% acquisition mode is in fact correct for the file we just loaded.
% Otherwise, we should kick it back to the safe file.
%
if(~isempty(df) && DEVICE_ID ~= -1)
    [AmpStatus, amp_err] = compare_modes(df.Data_Mode.v); % check against the putative move
    if(amp_err)
        return;
    end;
end;

if(nargout == 0) % no output - place it globally and DO things to it

    STIM = deal(sf); % get it back (somehow, "deal" is needed to copy over the cell arrays as well).
    if(~isempty(unblank(STIM.Addchannel.v)))
        g2(STIM.Addchannel.v);
        fprintf(1, 'getting %s\n', STIM.Addchannel.v);
    else
        if(~isempty(unblank(STIM.Superimpose.v)))
            g2(STIM.Superimpose.v);
        end;
    end;
    if(~isempty(unblank(STIM.AcqFile.v)))
        ga(STIM.AcqFile.v);  % first get the acquisition file
    else
        if(strmatch('DFILE', x, 'exact'))
            DFILE = df; % retrieve acq parameters from the internal file
            struct_edit('load', DFILE);
        end;
        struct_edit('load', STIM); % then do the new stim file so its up last
        pv('-p'); % execute a preview with no calculation - just display it.
    end;
        set_hold;
    if(strmatch('ONLINE', x, 'exact'))
        on_line('init', -1); % make sure we are cleared first....
        ONLINE = onl; % no struct_edit for online analysis - handled by a window....
        on_line('update'); % but update window if it is displayed.
    end;
    if(strmatch('DISPCTL', x, 'exact'))
        DISPCTL = displaycontrol; % get display control variable
    end;
    QueMessage(sprintf('g: Stim Params loaded from %s', sfilename));
else % an output - ? just return the structure in the designated argument
    varargout(1) = {a.STIM};
    if(nargout == 2 && strmatch('DFILE', x, 'exact'))
        if(~isempty(a.DFILE))
            varargout(2) = {a.DFILE};
        else
            varargout(2) = [];
        end;
    end;
    QueMessage(sprintf('Stim Params returned from %s', sfilename));
end;
return;
