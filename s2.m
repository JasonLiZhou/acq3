function s2(sfilename)
% s: Save the current stimulus parameters (in STIM2) to disk
% ***CMD***
% The line above specifies this file as avaialable at the command line in
% acq3

% Usage
%     s <cr> opens a dialog box for saving the stim parameters
%     s filename attempts to save the stim parameters in the file filename

% 7/10/2000
% Paul B. Manis   pmanis@med.unc.edu
%
% call s filename; if just called with s, then will use uiputfile
% to prompt for a filename
% NOTE: if filename is not same as stim.name, then stim.name will be set to the filename...
% else if there is no filename, we will suggest using stim.name...
%

global STIM2 CONFIG  FILEFORMAT

if(isempty(STIM2))
    QueMessage('s2: STIM2 has Empty Protocol - no save');
    return
end
cd(CONFIG.BasePath.v);
if(exist(CONFIG.StmPath.v, 'dir') == 7)
    wd = cd(CONFIG.StmPath.v);
else
    QueMessage(sprintf('s: Configuration StmPath %s invalid', CONFIG.StmPath.v),1);
    return;
end;

% require properly calculated waveforms before a save.
if(STIM2.update == 0)
    QueMessage('Stim protocol needs update- no save', 1);
    cd(CONFIG.BasePath.v);
    return;
end;

STIM = STIM2;
internal = STIM.Name.v;
if(nargin == 0)
    sug = sprintf('%s.mat', internal);
    [stimname, stimpath] = uiputfile(sug,'Save Stimulus(2) File');
    if(stimname == 0)
        cd(CONFIG.BasePath.v);
        return;
    end;
    sfilename=fullfile(stimpath, stimname);
end
[p, sfn, e] = fileparts(sfilename);

if(~strcmp(internal, sfn))
    answer = questdlg(sprintf('Filename (%s) and internal (%s) name do not match.\n Change internal name to match filename and save?', sfn, internal), 'Save Acq Param File');
    if(strcmp(answer, 'Yes'))
        STIM.Name.v = sfn;
        struct_edit('edit', STIM);
    else
        QueMessage('Stim structure NOT saved', 1);
        cd(CONFIG.BasePath.v);
        return;
    end;
end;

if(~isempty(FILEFORMAT))
    save(sfilename, 'STIM', FILEFORMAT);
else
    save(sfilename, 'STIM');
end;
QueMessage(sprintf('Stim2 Params saved in %s', sfilename), 1);
cd(CONFIG.BasePath.v);
return;
