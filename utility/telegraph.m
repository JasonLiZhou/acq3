function [AmpStatus] = telegraph(varargin)

% telegraph: read the telegraph channels associated with the amplifier
%
% default is to read Axo200/200B amplifiers
% ACH13 =  mode, ACH14 = gain, ACH15 = LPF
%
% the return is the amplifier status as a structure:
% AmpStatus.Gain (float)
% AmpStatus.Mode (character) - V (VC), T (track), 0 (I = 0), I (CC), F (IC fast)
% AmpStatus.LPF (float)

% modified 9/27/01 SCM
% using GETSAMPLE() routine instead of acquisition sequence
% add full range of modes for Axopatch 200B
% added code to specify amplifier

% modified 7/2/03 SCM
% added Multiclamp amplifier code

% return dummy values if NIDAQ not registered

% Modified, 4/2008 PBM
% handle multiclamps using server mode to the multiclamp commander
%

global ACQ_DEVICE HARDWARE %#ok<NUSED>
global DEVICE_ID WAI
global DFILE MCList AXPList


bus = 0;
if(nargin == 0)
    InputSelect = 1;
else
    InputSelect = varargin{1};
end;
amplifier_string = eval(sprintf('HARDWARE.InputDevice%d.Amplifier', InputSelect));
if(strcmpi(amplifier_string, 'TTL') || DEVICE_ID < 0)
    amplifier_string = 'none';
end;

% setup parameters based on amplifier type
switch (amplifier_string)

    case {'axoprobe', 'axoprobe1a'}     % no amplifier telegraphs
        AmpStatus.Data = [0 0 0];
        AmpStatus.Mode = 'I';
        AmpStatus.Gain = 10.0;
        AmpStatus.LPF = 5.0;

    case AXPList

        % ACH parameters
        tel_chan = [13 14 15];
        tel_range = [-10 10];

        % Axopatch mode telegraph
        mode_chan = 1;
        mode_tel = [6 4 3 2 1];
        mode_char = ['V', 'T', '0', 'I', 'F'];

        % Axopatch gain telegraph
        % telegraph should not read below 2 V in CC mode
        gain_chan = 2;
        gain_tel = [0.5  1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5];
        gain_vm  = [0.5  0.5 0.5 0.5 1   2   5   10  20  50  100 200 500];
        gain_im  = [0.05 0.1 0.2 0.5 1   2   5   10  20  50  100 200 500];

        % Axopatch LPF telegraph
        lpf_chan = 3;
        lpf_tel = [2 4 6 8 10];
        lpf_freq = [1 2 5 10 100];

        % create AI object if needed

        if (~validobj(WAI, 'analoginput'))
            fprintf(2, 'Creating %s Telegraph Input object\n', upper(ACQ_DEVICE));
            WAI = analoginput(ACQ_DEVICE, DEVICE_ID);
        end
        stop(WAI);
        delete(WAI.channel);

        % add channels and read telegraph channels
        set(WAI, 'InputType', 'NonReferencedSingleEnded');
        set(WAI, 'DriveAISenseToGround', 'On');
        ai_chans = addchannel(WAI, tel_chan);
        set(ai_chans, 'InputRange', tel_range);
        AmpStatus.Data = getsample(WAI);

        % obtain mode
        [mode_volt, mode_index] = min((AmpStatus.Data(mode_chan) - mode_tel).^2);
        AmpStatus.Mode = mode_char(mode_index);

        % obtain gain
        % mode determines whether Vm or Im gain provided
        [gain_volt, gain_index] = min((AmpStatus.Data(gain_chan) - gain_tel).^2);
        switch (AmpStatus.Mode)
            case {'V', 'T'}
                AmpStatus.Gain = gain_im(gain_index);
            case {'0', 'I', 'F'}
                AmpStatus.Gain = gain_vm(gain_index);
            otherwise
                AmpStatus.Gain = 1;
        end

        % obtain LPF
        [lpf_volt, lpf_index] = min((AmpStatus.Data(lpf_chan) - lpf_tel).^2);
        AmpStatus.LPF = lpf_freq(lpf_index);

    case {'multiclamp-dll'}

        % read MC700 telegraphs on both channels
        % store to Data field
        % otherwise use Axoprobe defaults
        AmpStatus.Data = mctelegraph(2, bus, 1);
        if (isstruct(AmpStatus.Data) && ~isempty(AmpStatus.Data))
            % AmpStatus.Data(2)=[];
            %AmpStatus.Data(2) = mctelegraph(1, bus, 2); % COM1, Bus 1, amp channel 1 (or 2...)

            % amplifier mode
            switch (AmpStatus.Data(1).mode)
                case 'V-Clamp' % voltage clamp
                    AmpStatus.Mode = 'V';
                case 'I-Clamp'  % current clamp
                    AmpStatus.Mode = 'I';
                case 'I = 0'    % I = 0
                    AmpStatus.Mode = '0';
                otherwise       % unknown
                    AmpStatus.Mode = 'X';
            end

            % convert gain to V/nA (VC) or V/V (CC)
            % base A/D unit should = 1 mV
            % units are assumed to be pA and mV!
            % THIS SHOULD CHANGE - CREATE FIELD TO SPECIFY UNITS!
            switch (AmpStatus.Data(1).scaled_unit)
                case 'V/mV'
                    AmpStatus.Gain = AmpStatus.Data(1).scaled_gain * (10 ^ 3);
                case 'V/uV'
                    AmpStatus.Gain = AmpStatus.Data(1).scaled_gain * (10 ^ 6);
                case 'V/A'
                    AmpStatus.Gain = AmpStatus.Data(1).scaled_gain * (10 ^ 9);
                case 'V/mA'
                    AmpStatus.Gain = AmpStatus.Data(1).scaled_gain * (10 ^ 6);
                case 'V/uA'
                    AmpStatus.Gain = AmpStatus.Data(1).scaled_gain * (10 ^ 3);
                case 'V/pA'
                    AmpStatus.Gain = AmpStatus.Data(1).scaled_gain * (10 ^ -3);
                otherwise   % includes V/mV and V/nA
                    AmpStatus.Gain = AmpStatus.Data(1).scaled_gain;
            end

            % convert LPF to kHz
            if (strcmp(AmpStatus.Data(1).lpf_unit, 'Hz'))
                AmpStatus.LPF = AmpStatus.Data(1).lpf / 1000;
            else
                AmpStatus.LPF = AmpStatus.Data(1).lpf;
            end

            % modify external command scaling in CONFIG block
            % don't bother if zero, external command is off
            % scaling can be changed in CONFIG_AO if needed
            output_range = [-10 10];    % DEFAULT AO RANGE
            if (AmpStatus.Data(1).extcmd > 0)
                switch (AmpStatus.Data(1).extcmd_unit)
                    case 'uV/V'
                        ext_cmd = AmpStatus.Data(1).extcmd * output_range * (10 ^ -3);
                    case 'V/V'
                        ext_cmd = AmpStatus.Data(1).extcmd * output_range * (10 ^ 3);
                    case 'nA/V'
                        ext_cmd = AmpStatus.Data(1).extcmd * output_range * (10 ^ 3);
                    case 'uA/V'
                        ext_cmd = AmpStatus.Data(1).extcmd * output_range * (10 ^ 6);
                    otherwise   % includes mV/V and pA/V
                        ext_cmd = AmpStatus.Data(1).extcmd * output_range;
                end
                switch (AmpStatus.Mode)
                    case 'V'
                        CONFIG.VCScale.v = ext_cmd(2);
                    case {'I', '0'}
                        CONFIG.CCScale.v = ext_cmd(2);
                end
            end
        else
            AmpStatus.Mode = 'I';
            AmpStatus.Gain = 10.0;
            AmpStatus.LPF = 5.0;
        end
    case MCList % all multiclamp amplifiers

        % read MC700B telegraphs on both channels
        % store to Data field
        % otherwise use Axoprobe defaults
        Data = mc700btelegraph();
        if(isempty(Data)) % unable to make a connection...
            return;
        end;
        AmpStatus = [];
        AmpStatus.Data = [];
        AmpStatus.Data = Data;
        if (isstruct(AmpStatus.Data) && ~isempty(AmpStatus.Data))
            for i = 1:length(AmpStatus.Data)
                % amplifier mode
                switch (AmpStatus.Data(i).mode)
                    case 'V-Clamp' % voltage clamp
                        AmpStatus.Mode(i) = 'V';
                    case 'I-Clamp'  % current clamp
                        AmpStatus.Mode(i) = 'I';
                    case 'I = 0'    % I = 0
                        AmpStatus.Mode(i) = '0';
                    otherwise       % unknown
                        AmpStatus.Mode(i) = 'X';
                end

                % convert gain to V/nA (VC) or V/V (CC)
                % base A/D unit should = 1 mV
                % units are assumed to be pA and mV!
                % THIS SHOULD CHANGE - CREATE FIELD TO SPECIFY UNITS!
                switch (AmpStatus.Data(i).scaled_unit)
                    case 'V/mV'
                        AmpStatus.Gain(i) = AmpStatus.Data(i).scaled_gain * (10 ^ 3);
                    case 'V/uV'
                        AmpStatus.Gain(i) = AmpStatus.Data(i).scaled_gain * (10 ^ 6);
                    case 'V/A'
                        AmpStatus.Gain(i) = AmpStatus.Data(i).scaled_gain * (10 ^ 9);
                    case 'V/mA'
                        AmpStatus.Gain(i) = AmpStatus.Data(i).scaled_gain * (10 ^ 6);
                    case 'V/uA'
                        AmpStatus.Gain(i) = AmpStatus.Data(i).scaled_gain * (10 ^ 3);
                    case 'V/pA'
                        AmpStatus.Gain(i) = AmpStatus.Data(i).scaled_gain * (10 ^ -3);
                    otherwise   % includes V/mV and V/nA
                        AmpStatus.Gain(i) = AmpStatus.Data(i).scaled_gain;
                end

                % convert LPF to kHz
                if (strcmp(AmpStatus.Data(i).lpf_unit, 'Hz'))
                    AmpStatus.LPF(i) = AmpStatus.Data(i).lpf / 1000;
                else
                    AmpStatus.LPF(i) = AmpStatus.Data(1).lpf;
                end

                % modify external command scaling in CONFIG block
                % don't bother if zero, external command is off
                % scaling can be changed in CONFIG_AO if needed
                output_range = [-10 10];    % DEFAULT AO RANGE
                switch(AmpStatus.Data(i).mode)
                    case 'V-Clamp'
                        if (AmpStatus.Data(i).VC_extcmd > 0)
                            switch (AmpStatus.Data(1).VC_extcmd_unit)
                                case 'uV/V'
                                    ext_cmd = AmpStatus.Data(i).VC_extcmd * output_range * (10 ^ -3);
                                case 'V/V'
                                    ext_cmd = AmpStatus.Data(i).VC_extcmd * output_range * (10 ^ 3);
                                otherwise   % includes mV/V
                                    ext_cmd = AmpStatus.Data(i).VC_extcmd * output_range;
                            end
                        end;
                        AmpStatus.ExtScale(i) = ext_cmd(2);
                    case 'I-Clamp'
                        if (AmpStatus.Data(i).CC_extcmd > 0)
                            switch (AmpStatus.Data(1).CC_extcmd_unit)
                                case 'nA/V'
                                    ext_cmd = AmpStatus.Data(i).CC_extcmd * output_range * (10 ^ 3);
                                case 'uA/V'
                                    ext_cmd = AmpStatus.Data(i).CC_extcmd * output_range * (10 ^ 6);
                                otherwise   % includes pA/V
                                    ext_cmd = AmpStatus.Data(i).CC_extcmd * output_range;
                            end;
                            AmpStatus.ExtScale(i) = ext_cmd(2);
                        end;
                end
            end; % of the for looop across channels.
        else
            AmpStatus.Mode = 'I';
            AmpStatus.Gain = 10.0;
            AmpStatus.LPF = 5.0;
        end

    otherwise

        % unknown amplifier
        % base settings on acquisition settings

        AmpStatus.Data = [0 0 0];
        switch (upper(DFILE.Data_Mode.v))
            case 'CC'
                AmpStatus.Mode = 'I';
                AmpStatus.Gain = 50.0;
            case 'VC'
                AmpStatus.Mode = 'V';
                AmpStatus.Gain = 1.0;
            otherwise
                AmpStatus.Mode = 'X';
                AmpStatus.Gain = 1.0;
        end
        AmpStatus.LPF = 10.0;
end
return
