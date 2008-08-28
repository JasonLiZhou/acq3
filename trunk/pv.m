function [argo] = pv(varargin)
% pv: Preview display of the command waveforms
% ***CMD***
% The line above specifies this file as avaialable at the command line in
% acq3

% Usage
%   pv <cr> generates the waveforms associated with the current STIM structure
%   pv(stile) generates the waveforms associated with the input sfile argument, which
%      must be a STIM style structure
%   out = pv () returns the stim structure with the computed waveform and any updated variables

% 7/10/2000
% Paul B. Manis, Ph.D.   pmanis@med.unc.edu
% second parameter nodisp: prevents data from being displayed if it is present (value is irrelevant)

% 1/14/2002
% PBM. Adjusted logic to correctly load secondary stimulus. Note that secondary stimulus is actually
% generated by combine.m, as called at the end of the methods (steps, pulses, noise, ramp, etc.).
% The waveforms are stored in struct.waveform.v, v2, vsco, v2sco.
% Since calling the method also computes the addchannel/superimpose waveform, this is all that needs to
% be done.
% singular updates of structures can be accomplished by calling:
% STIM2 = pv(STIM2, 1) (which updates STIM2 into STIM2, without displaying the result).
%

%
global STIM STIM2

pv_mode = 0;

if(nargin >= 1)
    sfile = varargin{1};
else
    sfile = STIM; % use the default one
end;
if(nargin >= 2)
    nodisp = varargin{2};
else
    nodisp = 0;
end;

if(isstruct(sfile) && nargout ~= 0)
    argo = sfile; % just set it as default
end;

if(~isstruct(sfile) && strcmp(sfile, '-f'))
    STIM2.update = 0;
    if(~strcmp(STIM2.Method.v, 'audnerve')) % protection.
        STIM2=pv(STIM2, 1);
        sfile = STIM; % this means use default stim
        sfile.update = 0; % but force the update
        pv_mode = 1; % special "force" mode - make sure global variable is updated
    else
        STIM2.update = 1;
        sfile = STIM2;% get from secondary stimulus and force a recalculate.
    end;

    % regardless of whether we specify an output or not.
end;

if(~isstruct(sfile) && strmatch(sfile, '-p') && nodisp == 0) % just plot (that's all, no calculation)
    pv_plot(STIM);
    return;
end;


if(sfile.update == 0 || isempty(sfile.waveform)) % stimulus needs an update - generate it
    QueMessage('PV: computing...');
    % try
    [outdata, time_base, out_rate, err] = eval(sprintf('%s(sfile);',  sfile.Method.v));
    % catch
    %     QueMessage('PV: Stimulus Genenration Error (Fatal)', 1);
    %     return;
    % end;
    if(err ~= 0)
        QueMessage('PV: Stimulus generation error');
        return;
    end;
    if(size(time_base, 1) ~= size(outdata, 1))
        outdata = outdata';
    end;
    if(size(time_base) ~= size(outdata))
        QueMessage('PV: Sizes of stim and time_base not matching?'); % this really should not occur
        return;
    end;
    if(nargin < 2 || nodisp == 0)
        QueMessage('PV: waveform computed', 1);
    end;
    l=length(outdata);
    sfile.waveform = [];
    sfile.tbase=[];
    sfile.waveform{1}.vsco = outdata{1}.vsco;
    if(strmatch('v2sco', fieldnames(outdata{1})))
        sfile.waveform{1}.v2sco = outdata{1}.v2sco;
    end;
    sfile.tbase{1}.vsco = time_base{1}.vsco;
    for i = 1:l
        sfile.waveform{i}.v = outdata{i}.v; % store waveform here ... we can use it later.
        if(strmatch('v2', fieldnames(outdata{i})))
            sfile.waveform{i}.v2 = outdata{i}.v2;
        end;
        sfile.tbase{i}.v = time_base{i}.v;
        sfile.outrate = out_rate;
    end;
    sfile.update = 1; % we computed - set the flag
else
    if(nodisp == 0)
        QueMessage('PV: waveform is current');
    end;
end;


if(nargout > 0)
    argo = sfile;
end;
if(nargin == 0 || pv_mode == 1) % no input args or "force" mode ('-f') are asking for update in global variable
    STIM = sfile;
end;

if(nodisp == 1) % nodisp might be set, don't bother with updating display
    return;
end;

pv_plot(STIM);
return;


function pv_plot(stimfile)

% now plot the waveform in sfile
h0 = findobj('Tag', 'Acq'); % get the big window
if(ishandle(h0))
    figure(h0); % force to be on top when we do this
end;
figsz=get(h0, 'Position');
hu = findobj('Tag', 'UtilityFrame'); % Plot in utility window
if(~isempty(hu))
    % make the on-line window (1)
    set(hu, 'Visible', 'off');
end;
hc = get(hu, 'UserData'); % get list of handles in the frame
if(~isempty(hc))
    for i=1:length(hc)
        if(ishandle(hc(i)))
            delete(hc(i));
        end;
    end
end;
hc = []; % clear the handle list.
set(hu, 'UserData', hc); % keep it synchronized

framesz = get(hu, 'Position');
fsize = 7;
c_ax = [0.37 0.37 0.8];
pvw1=[0.08 0.08 0.84 0.45];
pvf1 = frameit(pvw1, framesz, figsz);
hp(1)=subplot('position', [pvf1.left, pvf1.bottom, pvf1.width, pvf1.height]);
p_type = 0; % stairs is default
if(strmatch(stimfile.Method.v, {'noise', 'alpha', 'sine', 'audnerve'}))
    p_type = 1;
end;

maxpltpts = 1024;

for i=1:length(stimfile.waveform)
    np = length(stimfile.waveform{i}.v);
    skip = 1;
    if(np > maxpltpts)
        skip = floor(np/maxpltpts);
    end;
    if(~p_type)
        [x1, y1] = stairs(stimfile.tbase{i}.v, stimfile.waveform{i}.v);
        plot(x1, y1, '-w');
    else
        plot(stimfile.tbase{i}.v(1:skip:end), stimfile.waveform{i}.v(1:skip:end), '-w');
    end;
    hold on;
end;
if(~isempty(strmatch('vsco', fieldnames(stimfile.waveform{1}))))
    np = length(stimfile.waveform{1}.vsco);
    skip = 1;
    if(np > maxpltpts)
        skip = floor(np/maxpltpts);
    end;
    if(~p_type)
        [x1, y1] = stairs(stimfile.tbase{1}.vsco, stimfile.waveform{1}.vsco);
        plot(x1, y1, '-r');
    else
        plot(stimfile.tbase{1}.vsco(1:skip:end), stimfile.waveform{1}.vsco(1:skip:end), '-r');
    end;
end;
set(gca, 'Tag', 'ACQ_DAC0');
acq_setcrosshair(gca, 'DAC0', 'ms', '', ...
    [pvf1.left+pvf1.width*0.95 pvf1.bottom+pvf1.height*0.5 pvf1.width*0.22 pvf1.height*0.2]);

ha = gca;
set(ha,'box','off');
set(ha, 'color', 'black');
set(ha, 'XColor', c_ax);
set(ha, 'YColor', c_ax);
set(ha, 'Fontsize', fsize);
set_axis;

pvw2=[0.08 0.65 0.84 0.35];
pvf2 = frameit(pvw2, framesz, figsz);
hp(2)=subplot('position', [pvf2.left, pvf2.bottom, pvf2.width, pvf2.height]);

for i = 1:length(stimfile.waveform)
    if(strmatch('v2', fieldnames(stimfile.waveform{i})))
        np = length(stimfile.waveform{i}.v2);
        skip = 1;
        if(np > maxpltpts)
            skip = floor(np/maxpltpts);
        end;
        if(~p_type)
            [x2, y2] =  stairs(stimfile.tbase{i}.v, stimfile.waveform{i}.v2);
            plot(x2, y2, '-m');
        else
            plot(stimfile.tbase{i}.v(1:skip:end), stimfile.waveform{i}.v2(1:skip:end), '-m');
        end;
        hold on;
    end;
end;
if(strmatch('v2sco', fieldnames(stimfile.waveform{1})))
    np = length(stimfile.waveform{1}.v2sco);
    skip = 1;
    if(np > maxpltpts)
        skip = floor(np/maxpltpts);
    end;
    if(~p_type)
        [x2, y2] =  stairs(stimfile.tbase{1}.vsco, stimfile.waveform{1}.v2sco);
        plot(x2, y2, '-r');
    else
        plot(stimfile.tbase{1}.vsco(1:skip:end), stimfile.waveform{1}.v2sco(1:skip:end), '-r');
    end;
end;
set(gca, 'Tag', 'ACQ_DAC1');
acq_setcrosshair(gca, 'DAC1', 'ms', '', ...
    [pvf2.left+pvf2.width*0.95 pvf2.bottom+pvf2.height*0.5 pvf2.width*0.22 pvf2.height*0.2]);

ha = gca;
set(ha,'box','off');
set(ha, 'color', 'black');
set(ha, 'XColor', c_ax);
set(ha, 'YColor', c_ax);
set(ha, 'Fontsize', fsize);
%set(ha, 'XTickLabel', '');
set_axis;


set(hu, 'UserData', hp);


return;




function set_axis()
% set current axes to encompass the data
v = axis;
if(v(3) < 0)
    v(3) = v(3)*1.1;
else
    v(3) = v(3)*0.9;
end;
if(v(4) < 0)
    v(4) = v(4)*0.9;
else
    v(4) = v(4)*1.1;
end;
if(v(3) == 0)
    v(3) = -0.1 * v(4);
end;
if(v(4) == 0)
    v(4) = -0.1*v(3);
end;
axis(v);
return;


