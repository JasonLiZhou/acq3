function [s] = pulse_edit(cmd)
% Usage: pulse_edit(cmd)
%  called internally with 'edit stim2'. Creates a GUI to adjust the stimulus parameters for PULSE waveforms
%  only. future versions might implement other parameters...
%  7/01 Paul B. Manis pmanis@med.unc.edu
%  first version: rough, but works.
%  1/02 Second version. Cleaned up. Doesn't call 'stimcontrol' routines any more (which caused some
% significant confusion.....
%

global  STIM STIM2 % reference secondary stimulus; also primary so we can update it.
global SCOPE_FLAG
persistent old_lratio
stimtype = 0;
if(strmatch(lower(STIM2.Method.v), 'testpulse', 'exact'))
    stimtype = 1; % indicate test pulse method.
end;

if(nargin == 0) % when called with no command, build the window or update it with the new information
    old_lratio = 0;

    if(isempty(STIM2)) % ? no block
        g2; % get a secondary stimulus parameter block
        if(isempty(STIM2))
            return;
        end;

    end;
    if(~strmatch(lower(STIM2.Method.v), strvcat('pulse', 'burst', 'testpulse'), 'exact')) % the method must be pulse
        QueMessage('pulse_edit: Require stimulus method PULSE or TESTPULSE', 1);
        return;
    end;
    STIM2.LevelFlag.v = 'absolute';
    stim_pv;
    % method is pulse, so we can go ahead and make a new window for the controls

    h = findobj('Tag', 'PEdit');
    if(isempty(h))
        %open('pulse_editor.fig');
        pulse_editor_fig(); % call our m-routine instead of guide
        h = findobj('Tag', 'PEdit');
        set(h, 'menubar', 'none');
        set(h, 'toolbar', 'none');
        local_Update;
    else
        figure(h);
    end;


else
    switch(cmd)
        case 'slider'
            hp = findobj('Tag', 'PEdit_level');
            hs = findobj('Tag', 'PEdit_slider');
            newlevel = get(hs, 'Value');
            if(STIM2.Scale.v < 0)
                newlevel = abs(newlevel);
            end;
            set(hp, 'String', sprintf('%7.2f', newlevel));
            pulse_edit('level');
            return;

        case 'changesign'
            hp = findobj('Tag', 'PEdit_negative');
            negflag = get(hp, 'value'); % if box is checked, use negative leading; negflag will be 1
            if(negflag)
                STIM2.Scale.v = -abs(STIM2.Scale.v);
            else
                STIM2.Scale.v = abs(STIM2.Scale.v);
            end;
            hp = findobj('Tag', 'PEdit_level');
            newlevel = str2num(get(hp, 'string'));
            if(STIM2.Scale.v < 0)
                newlevel = abs(newlevel);
            else
                newlevel = abs(newlevel);
            end;

            set(hp, 'String', sprintf('%7.2f', newlevel));
            pulse_edit('level');

        case 'npulse'
            hcmd = findobj('Tag', 'PEdit_npulse');
            oldnp = STIM2.Npulses.v;
            np = get(hcmd, 'string');
            STIM2.Npulses.v = floor(str2num(np));
            if(oldnp ~= STIM2.Npulses.v) % if it changed, update it.
                stim_pv;
            end;

        case 'ipi'
            hcmd = findobj('Tag', 'PEdit_ipi');
            oldipi = STIM2.IPI.v;
            ipi = get(hcmd, 'string');
            STIM2.IPI.v = str2num(ipi);
            if(oldipi ~= STIM2.IPI.v)
                stim_pv;
            end;

        case 'delay'
            hcmd = findobj('Tag', 'PEdit_delay');
            olddelay = STIM2.Delay.v;
            delay = get(hcmd, 'string');;
            STIM2.Delay.v = str2num(delay);
            if(olddelay ~= STIM2.Delay.v)
                stim_pv;
            end;

        case 'durp1'
            hcmd = findobj('Tag', 'PEdit_durp1');
            olddur1 = STIM2.Duration.v(1);
            dur1 = get(hcmd, 'string');
            STIM2.Duration.v(1) = str2num(dur1);
            if(olddur1 ~= STIM2.Duration.v(1))
                stim_pv;
            end;

        case 'durp2'
            hcmd = findobj('Tag', 'PEdit_durp2');
            olddur2 = STIM2.Duration.v(2);
            dur2 = get(hcmd, 'string');
            STIM2.Duration.v(2) = str2num(dur2);
            if(olddur2 ~= STIM2.Duration.v(2))
                stim_pv;
            end;
        case 'scale'
            hcmd = findobj('Tag', 'PEdit_scale');
            oldscale = STIM2.Scale.v;
            scale = get(hcmd, 'string');
            STIM2.Scale.v = str2num(scale);
            if(oldscale ~= STIM2.Scale.v)
                stim_pv;
            end;

        case {'level', 'l1l2'}
            hcmd = findobj('Tag', 'PEdit_level');
            lev = str2num(get(hcmd, 'String'));
            oldlev = STIM2.Level.v(1);
            hrat = findobj('Tag', 'PEdit_l1l2'); % get the ratio
            lratio = str2num(get(hrat, 'String'));
            STIM2.Level.v(1) = lev;
            STIM2.Level.v(2) = lev*lratio;
            STIM2.LevelFlag.v = 'absolute';
            hslider = findobj('Tag', 'PEdit_slider');
            if(STIM2.Scale.v > 0)
                set(hslider, 'value', STIM2.Level.v(1)); % move the slider to match the value we typed in.
            else
                set(hslider, 'value', STIM2.Level.v(1));
            end;
            % note slider only shows positive numbers...
            if(stimtype == 999) % only let it edit these directly if not in testpulse mode.
                hs = findobj('tag', 'PEdit_sequence');
                STIM2.Sequence.v = sprintf('%7.1f', STIM2.Level.v(1));
                set(hs, 'string', STIM2.Sequence.v);
                STIM2.SeqParList.v = 'Level';
                hs = findobj('tag', 'PEdit_Seqpar');
                set(hs, 'string', 'level');
                STIM2.SeqStepList.v = 1;
                hs = findobj('tag', 'PEdit_seqparn');
                set(hs, 'string', 1);
            end;
            if(oldlev ~= STIM2.Level.v(1) | old_lratio ~= lratio)
                stim_pv;
            end;

        case 'seqpar'
            hcmd = findobj('Tag', 'PEdit_Seqpar');
            sno = get(hcmd, 'String');
            oldsno = STIM2.SeqParList.v;
            STIM2.SeqParList.v = sno;
            if(~strcmp(oldsno,STIM2.SeqParList.v))
                stim_pv;
            end;

        case 'seqparn'
            hcmd = findobj('Tag', 'PEdit_seqparn');
            sno = get(hcmd, 'String');
            oldsno = STIM2.SeqStepList.v;
            STIM2.SeqStepList.v = str2num(sn{1});
            if(length(STIM2.SeqStepList.v) > 1)
                STIM2.SeqStepList.v = STIM2.SeqStepList.v(1);
            end;
            if(oldsno ~= STIM2.SeqStepList.v)
                stim_pv;
            end;

        case 'sequence'
            hcmd = findobj('Tag', 'PEdit_sequence');
            sno = get(hcmd, 'String');
            oldsno = STIM2.Sequence.v;
            STIM2.Sequence.v = sno;
            if(~strcmp(oldsno,STIM2.Sequence.v))
                stim_pv;
            end;

        case 'testlevel'
            if(stimtype == 1)
                hcmd = findobj('Tag', 'PEdit_TestLevel');
                sno = get(hcmd, 'String');
                oldsno = STIM2.TestLevel.v;
                STIM2.TestLevel.v = str2num(sno);
                if(oldsno ~= STIM2.TestLevel.v)
                    stim_pv;
                end;
            end;

        case 'testduration'
            if(stimtype == 1)
                hcmd = findobj('Tag', 'PEdit_TestDuration');
                sno = get(hcmd, 'String');
                oldsno = STIM2.TestDuration.v;
                STIM2.TestDuration.v = str2num(sno);
                if(oldsno ~= STIM2.TestDuration.v)
                    stim_pv;
                end;
            end;

        case 'testdelay'
            if(stimtype == 1)
                hcmd = findobj('Tag', 'PEdit_TestDelay');
                sno = get(hcmd, 'String');
                oldsno = STIM2.TestDelay.v;
                STIM2.TestDelay.v = str2num(sno);
                if(oldsno ~= STIM2.TestDelay.v)
                    stim_pv;
                end;
            end;

            % button commands:

        case {'close', 'exit'}
            h = findobj('Tag', 'PEdit');
            close(h);
            return;

        case 'open'
            g2;
            if(isempty(STIM2))
                return;
            end;
            if(~strcmp(STIM2.Method.v, 'pulse'))
                QueMessage('pulse_edit: Requires stimulus method PULSE', 1);
                return;
            end;
            h = findobj('Tag', 'PEdit');
            if(ishandle(h))
                set(h, 'Name', sprintf('Pulse Editor: %s', STIM2.Name.v));
            end;
            local_Update;
            stim_pv;


        case 'changefile'
            if(isempty(STIM2))
                return;
            end;
            if(~strcmp(STIM2.Method.v, {'pulse','testpulse'})) % only if we are pulse mode
                return;
            end;
            h = findobj('tag', 'PEdit');
            if(ishandle(h))
                set(h, 'Name', sprintf('Pulse Editor: %s', STIM2.Name.v));
            end;
            local_Update;
            stim_pv;
            fprintf(1, 'STIM2 changed in P_Edit\n');
            
        case 'save'
            s2(STIM2.Name.v);

        case 'update'
            %  STIM2.Sequence.v = sprintf('%8.1f', STIM2.Level.v(1));
            %  hcmd = findobj('Tag', 'PEdit_sequence');
            %  set(hcmd, 'String', STIM2.Sequence.v);
            %stim_pv; % recalculate our local waveform
            s2(STIM2.Name.v); % save the file to disk....
            %  STIM.update = 0;
            STIM2.update = 0;
            pv('-f'); % force update of main one too
            if(SCOPE_FLAG) % if we are in scope mode, stop and restart to update the stimulus.
                acq_stop;
                scope;
            end;
            h = findobj('Tag', 'PEdit');
            figure(h);

        case 'PV' % just preview locally....
            stim_pv;

        case 'addchannel' % force to add channel with main stimulus...
            STIM.Addchannel.v = STIM2.Name.v;
            struct_edit('redisplay', STIM);
            stim_pv;
            s2(STIM2.Name.v);
            pv('-f'); % force update of main one
            if(SCOPE_FLAG) % if we are in scope mode, stop and restart to update the stimulus.
                acq_stop;
                scope;
            end;


        otherwise
            QueMessage(sprintf('pulse_edit: Unrecognized Command: %s', cmd));
            return;
    end;
end;


function local_Update()
global STIM2;

h = findobj('tag', 'PEdit');

set(h, 'Name', sprintf('Pulse Editor: %s', STIM2.Name.v)); % display name in the title bar field.

h = findobj('tag', 'PEdit_negative');
if(STIM2.Scale.v < 0)
    set(h, 'value', 1);
else
    set(h, 'value', 0);
end;
h = findobj('tag', 'PEdit_slider');
set(h, 'value', abs(STIM2.Level.v(1)));
set(h, 'min', 0);
set(h, 'max', 1000);
h = findobj('tag', 'PEdit_level');
set(h, 'string', sprintf('%7.2f', STIM2.Level.v(1)));
if(length(STIM2.Level.v) > 1)
    h = findobj('tag', 'PEdit_l1l2');
    set(h, 'string', sprintf('%7.2f', STIM2.Level.v(2)/STIM2.Level.v(1)));
end;
h = findobj('tag', 'PEdit_npulse');
set(h, 'string', sprintf('%d', STIM2.Npulses.v));
h = findobj('tag', 'PEdit_ipi');
set(h, 'string', sprintf('%7.1f', STIM2.IPI.v));
h = findobj('tag', 'PEdit_durp1');
set(h, 'string', sprintf('%7.1f', STIM2.Duration.v(1)));
if(length(STIM2.Duration.v) > 1)
    h = findobj('tag', 'PEdit_durp2');
    set(h, 'string', sprintf('%7.1f', STIM2.Duration.v(2)));
end;
h = findobj('tag', 'PEdit_delay');
set(h, 'string', sprintf('%7.1f', STIM2.Delay.v));
h = findobj('tag', 'PEdit_Seqpar');
set(h, 'string', sprintf('%s', STIM2.SeqParList.v));
h = findobj('tag', 'PEdit_seqstepn');
set(h, 'string', sprintf('%d', STIM2.SeqStepList.v));
h = findobj('tag', 'PEdit_sequence');
set(h, 'string', sprintf('%s', STIM2.Sequence.v));
if(strmatch(STIM2.Method.v, 'testpulse', 'exact'))
    h = findobj('tag', 'PEdit_TestLevel');
    set(h, 'string', sprintf('%s', num2str(STIM2.TestLevel.v)));
    h = findobj('tag', 'PEdit_TestDuration');
    set(h, 'string', sprintf('%s', num2str(STIM2.TestDuration.v)));
    h = findobj('tag', 'PEdit_TestDelay');
    set(h, 'string', sprintf('%s', num2str(STIM2.TestDelay.v)));
end;


hg = findobj('tag', 'PEdit_graph');
set(hg, 'FontSize', 7);
stim_pv;
return;


function stim_pv()
global STIM2
STIM2.update = 0;
STIM2 = pv(STIM2, 1); % update without showing the display; return updated structure to us.

hp = findobj('tag', 'PEdit_graph');
if(isempty(hp))
    return;
end;
cla(hp);
hg = findobj('tag', 'PEdit_graph');
set(hg, 'FontSize', 7);
n = length(STIM2.tbase);
for i = 1:n
    line(STIM2.tbase{i}.v, STIM2.waveform{i}.v, 'Parent', hp, 'color', 'black'); % now display our own copy of the data.
    hold on;
end;
line(STIM2.tbase{1}.vsco, STIM2.waveform{1}.vsco, 'Parent', hp, 'color', 'red');
return;


