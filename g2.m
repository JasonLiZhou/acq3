function varargout = g2(sfilename)
% g2: get a stimulus file from disk
% ***CMD***
% The line above specifies this file as avaialable at the command line in
% acq3

% Usage
%     g2 [filename] gets and loads the sfile structures
%     from the selected file, into the secondary stimulus block
%		the dfile is not loaded.
%     If no filename is specified, a browser window is provided to select a file.

% based on g.m for loading a single file.
% 7/10/2000 - get a stimulus file from disk.
% Paul B. Manis   pmanis@med.unc.edu
% returns the loaded sfile structure in global variable SFILE.
% If you call without a filename on the command line, then
% this routine will use uigetfile to do the file access
% if there is an output argument, the data is returned there rather than in
% the global variable stim (9/11/2000 P. Manis)
% if there is an acq file stored in the stim file, then use it (makes AcqFile empty
% so when we save it the current acq structure is saved).
%
global STIM2 CONFIG IN_ACQ

if(IN_ACQ)
    QueMessage('Already in acquisition: cannot change protocols', 1);
end;

onl = [];
if(nargout > 0)
    for i = 1:nargout
        varargout{i} = []; % initialize the outputs if present
    end;
end;
% load a protocol from the disk
fullstmpath = [append_backslash(CONFIG.BasePath.v) CONFIG.StmPath.v];
if(exist(fullstmpath, 'dir') == 7)
    wd = cd(fullstmpath);
else
    QueMessage(sprintf('g2: Configuration StimPath %s invalid', fullstmpath), 1);
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
    QueMessage(sprintf('g2: File %s not found? ', sfilename), 1);
    cd(wd);
    return;
end;
fclose(fid);
a = load(sfilename);
sf=a.STIM;

cd(wd);
if(chkfile(sf))
    return;
end;
% if pulse editor is up and the type is "pulse", let's force it to
% reload.
pulse_edit('changefile'); % check it out.   

if(nargout == 0) % no output - place it globally and DO things to it
    STIM2 = sf; % get it back
    QueMessage(sprintf('g2: Stim2 Params loaded from %s', sfilename));
else % an output - ? just return the structure in the designated argument
    varargout(1) = {a.STIM};
    QueMessage(sprintf('g2: Stim2 Params returned from %s', sfilename));
end;
return;
