function [varargout] = acq3(varargin)
% ACQ3 - version 3 of ACQ program
% incorporates Scott's telegraphs,
% new stimulus protocols, etc.

% ACQ: main entry point for the data acquisition program
% Usage
%   Called with no arguments, will look for acquisition hardware
%   If no hardware is found, the program will run in a test mode.
%   Called with one argument (value of argument is immaterial), then
%   will run in test mode regardless.

% Sept1999-March 2000
% Paul B. Manis, Ph.D.
%
% pmanis@med.unc.edu
%
% version 3 includes many changes:
% configuration is handled by a text file
% acquisition uses new acquire_one routine with better timing
% display control is more flexible...
% etc.
% 4/2008 P. Manis
%
%--------------------------------------------------------------------
% Call with command (commands are text; parsed below by switch),
% Initial call is always empty.
% commands:
% the only command implemented is to init the configuration, as a callback from the
% profile manager. Everything else runs based on other callbacks..

% Program expects to see a National Instruments data acquisition board in the system
% and uses the capabilites of that board for input and output.
% When no board is found, the program runs in a 'test' mode that allows generation
% and testing of stimulus/acquisition modules and macros. Functionality may be limited.
%
% Configure NI boards as follows:
%		Connect PFI0/Trig1 to User 1 (BNC)
%		Connect DIO 1 to User 1 (jumper)
%		Connect DIO 0 to PFI6 (jumper)
% OR:
%		Connect PFIO/Trig1 to PFI16 and to DIO1.
%

% Globals are used to communicate information to different parts of the program.
% This is not elegant, but it is effective and fast

% Definition of globals:
% Note: some globals are structures, and some are simple variables.
% in the future some of the variables may be collapsed into a structure.

% DFILE: acquisition parameter structure. (the name is a holdover from the old datac program)
% STIM: stimulus parameter and waveform structure
% STIM2: space to editi a second stimulus structre that may not be in use, or is used in parallel
% DATA: storage for the data structure.
% CONFIG: basic configuration information (directories, user, etc).
% TEST_MODE: flag to indicate whether hardware found (set to 0), or not, in which case we run in test mode (1)
% RECORD_NO: running number of the number of traces collected into the current file
% CMDS: list of current commands - derivied from the names of m-files in the source directory (renewable)
% FILE_STATUS: structure holding record number, block number and note counter.
% AI, AO, DIO and TAI are DAQ data acquisition objects.
% STOP_ACQ, SCOPE_FLAG, IN_ACQ, SCOPE_RESTART, STOPPED_FLAG are flags controlling acquisition for
%    scope mode (where data is not stored to disk).
% IN_MACRO and STOP_MACRO are flags indicating when a macro is running, and requesting stop of macro.
% WIN_TITLE: the name of the frame currently visible for parameter editing (left-side pane). Controls
%    the action in struct_edit.
% DISPLIM: structure with data display axes channels I and V.
% CHLIM: structure for all channels.
% ONLINE: structure controlling the ONLINE analysis (partially implemented)
% HOLD_FLAG: when set, this implements a "slow voltage clamp" ini current clamp mode - it tries to keep
%    the membrane potential at an initial value near the end of each stimulus epoch.
% HOLD_CURRENT: the magnitude of the current most recently set for the holding function.
%

global DFILE DATA STIM STIM2 CONFIG BASEPATH
global ACQ_DEVICE TEST_MODEL  % control variables
global DEVICE_ID HARDWARE %#ok<NUSED>
global ONLINE ONLINE_DATA
global MCList AmpStatus
global MC700BConnection
global ACQVERSION ACQVERDATE

% start program - get initial setup to work with.
if(nargout > 0)
    varargout{1} = 0; % clear the error return flag if we ask for it
end;

if(nargin == 0) % no arguments - create a window and initialize the program - wait for user to select configuration
    ACQVERSION = 3.1;
    ACQVERDATE = '8/19/2008';
    warning('off','MATLAB:dispatcher:InexactCaseMatch')
    h = findobj('Tag', 'Acq'); % look for our window
    if(~isempty(h)) % a screen already exists - EXIT and let existing one run
        QueMessage('Only ONE instance of Acq allowed', 1');
        return;
    end;
    switch(computer)
        case 'PCWIN'
            BASEPATH = 'C:\Acq3'; % new version..... fixed directory for install
        case {'MAC', 'MACI'}
            [res homedir] = system('echo $HOME');
            BASEPATH = slash4OS(strcat(homedir, '/Desktop/acq3'));
    end;
    BASEPATH = append_backslash(BASEPATH);
    addpath(slash4OS([BASEPATH '/source']));
    addpath(slash4OS([BASEPATH '/source/utility']));
    %    acq_paths; % make sure all of our paths are available...
    cd (BASEPATH); % set our base path...

    fprintf(1, '\n\n\n*************************************************\n');
    fprintf(1, 'Welcome to ACQ Version %.1f (%s)\n', ACQVERSION, ACQVERDATE);
        
    % initialize the data structures.
    CONFIG = []; % configuration for program
    DFILE =[]; % acquisition parameter control structure
    DATA = []; % data (not used)
    STIM = []; % stimulus parameter
    STIM2 = []; % secondary stimulus parameters (second channel, superimpose, etc.).
    ONLINE = [];
    for i = 1:2
        ONLINE_DATA.dx{i} = [];
        ONLINE_DATA.dy{i} = [];
    end
    MC700BConnection = [];
    gh('find'); % get the hardware configuration file
    new('config'); % create a new configuration structure
    err=gc(slash4OS([BASEPATH 'configurations/configbase.ini'])); % load but do not display - always get the default configuration
    if(err)
        if(nargout > 0)
            varargout{1} = 1;
        end;
        return;
    end;

    profile_mgr; % load a profile (user configuration) from disk
    % uses version 7.6 guide call backs... 
    
    TEST_MODEL = 1; % set to first model...

else
    % there is an argument, so we must interpret argument here.

    switch(varargin{1}) % treat first argument as a command
        case 'exit'
            return; % simple exit
        case 'settestmode'
            ACQ_DEVICE = 'none'; % force to test mode - there is NO WAY BACK at the moment except to exit.
            DEVICE_ID = -1;

        case 'run' % go ahead and set it up.
            err = acq_run;
            if(err)
                bye;
            end;

        case 'mouse_motion'
            acq_do_ptr(varargin{2},0); % ctl should point to figure window...
        case 'mouse_down'
            acq_do_ptr(varargin{2}, 1);
        case 'mouse_up'
            acq_do_ptr(varargin{2}, 2);
        case 'connectamplifier'
            %disp 'connect... amp'
            switch(lower(CONFIG.Amplifier.v)) % make connection to computer-controlled amplifier
                case MCList
                    [conn, err]  = MC700('open');
                    if(~err)
                        MC700('close');
                        return;
                    end;
                    fprintf(2, 'ACQ3 ERROR: Could not connect to TCP server\n');
                    if(nargout > 0)
                        varargout{1} = 1;
                    end;
                    return;


                otherwise
            end;

        otherwise
            fprintf(2, 'ACQ3 ERROR: Argument %s not implemented in main routine\n', varargin{1});
    end; % of switch on commands
end; % of if statement on number of arguments passed to input



function [varargout] = acq_run()
global DFILE STIM STIM2 CONFIG BASEPATH FILEFORMAT
global ACQ_DEVICE CMDS % control variables
global DEVICE_ID FILE_STATUS MCList AXPList APRList
global AI AO DIO TAI % DAQ objects
global STOP_ACQ SCOPE_FLAG IN_ACQ SCOPE_RESTART STOPPED_FLAG % flags
global IN_MACRO STOP_MACRO
global WIN_TITLE DISPLIM CHLIM ONLINE
global HOLD_FLAG HOLD_CURRENT
global AmpStatus

if(nargout > 0)
    varargout{1} = 0;
end;

acq_main_screen; % create the one and only window

show_configuration;
%acq_stop; % mainly to reset the stop button color

h = findobj('Tag', 'Acq');
set(h, 'Name', sprintf('ACQ: Data Acquisition [configuration: %s]', CONFIG.Config.v));

% initialize the global variables - first create as nulls
ver=version;
if(ver(1) == '6')
    fprintf(1, 'Matlab is version 6, and data will be written in version 6 format\n');
    FILEFORMAT= '-v6';
elseif ver(1) == '7'
    FILEFORMAT = '-v7'; % for backwards compatability at expense of space
    fprintf(1, 'Matlab is version 7, and data will be written in version 7 format\n');
end;
STIM2 = [];
WIN_TITLE=[];
TAI = []; % Telegraph analog input object (DAQ)
AI=[]; % Acquisition analog input object (DAQ)
AO=[]; % Acquisition analog output object (DAQ)
DIO=[]; % Digital IO output object (DAQ)
CMDS=[];
STOP_ACQ = 0;  % flag to stop acquisition (set by button)
SCOPE_FLAG = 0; % flag set to 1 when in "scope" mode (not acquiring data)
IN_ACQ = 0; % flag set to 1 when "in" acquisition routine to prevent re-entry
SCOPE_RESTART = 0;
STOPPED_FLAG = 0;
IN_MACRO = 0;
STOP_MACRO = 0;
DISPLIM.I = [-1000, 1000]; % default display limits
DISPLIM.V = [-120, 60];
CHLIM(1).V = DISPLIM.I;
CHLIM(2).V = DISPLIM.V;
for i = 3:16
    CHLIM(i).V = [-500 500]; % remainder of possible display channels.
end;
HOLD_FLAG = 0; % holding current/flag.
HOLD_CURRENT = 0;

FILE_STATUS.Record = 1; % file status: record counter
FILE_STATUS.Block = 1; % file status: block counter
FILE_STATUS.NoteCount = 1; % file status: note counter

MCList = {'multiclamp', 'multiclamp700', 'multiclamp700a', 'multiclamp700b'}; % all mutlclamps
AXPList = {'axopatch', 'axopatch200', 'axopatch200a', 'axopatch200b'}; % all axopatches
APRList = {'axoprobe', 'axoprobe1a'};

% connect to the nidaq dll library and the hardware
% register hardware
% modified 4/23/02 SCM
% ACQ_DEVICE replaces TEST_MODE
% string to indicate what hardware found
ACQ_DEVICE = 'none';
DEVICE_ID = -1;
switch(computer)
    case {'PC', 'PCWIN'}
        % set up the NI acquisition and hardware interface
        if (exist('daqregister', 'file') == 2) % make sure toolbox and drivers are installed
            %         daqregister('nidaq');
            %        hw = daqhwinfo('nidaq');
            hw.AdaptorName = 'nidaq';
            if (strmatch('nidaq', hw.AdaptorName, 'exact'))
                ACQ_DEVICE = 'nidaq';
                DEVICE_ID = 1;
                notice = 'NIDAQ found and registered';
                if (~isempty(daqfind)) % causes preoblems - delete...
                    delete(daqfind);
                end
                daqreset % make sure devices are cleared and accessible.
                AO = analogoutput('nidaq', 'Dev1');
                if(~isvalid(AO))
                    fprintf(2, 'ACQ3 (acq_run): Unable to get Analog Output device - may need hardware reset\n');
                    if(nargout > 0)
                        varargout{1} = 1;
                    end;
                    return;
                end;

                AI = analoginput('nidaq', 'Dev1'); % get oure devices...
                if(~isvalid(AI))
                    fprintf(2, 'ACQ3 (acq_run): Unable to get Analog Input device - may need hardware reset\n');
                    if(nargout > 0)
                        varargout{1} = 1;
                    end;
                    return;
                end;
            else
                ACQ_DEVICE = 'none'; % no hardware - we have a dummy acquisition mode
                DEVICE_ID = -1;
                notice = 'NIDAQ/WINSOUND not found, running in test mode';
            end

        else
            ACQ_DEVICE = 'none'; % no hardware - we have a dummy acquisition mode
            DEVICE_ID = -1;
            notice = 'no hardware found, running in test mode';
        end
    case {'MAC', 'MACI'}
        ACQ_DEVICE = 'none'; % no hardware - we have a dummy acquisition mode
        DEVICE_ID = -1;
        notice = 'Computer is Mac: running in test mode';
    otherwise
        ACQ_DEVICE = 'none'; % no hardware - we have a dummy acquisition mode
        DEVICE_ID = -1;
        notice = 'Computer type not recognized, running in test mode'; %#ok<NASGU>
        return;
end;

if (~isempty(notice))
    fprintf(2, 'acq3: %s\n', notice);
end
AmpStatus = telegraph;
% err = show_ampstatus;
% if(err)
%     if(nargout > 0)
%         varargout{1} = 1;
%     end;
%     return;
% end;
command_gather([BASEPATH 'source']); % get the commands from the source directory beneath us
if(isempty(CMDS))
    close(h); % close the window.
    fprintf(2, 'ACQ3 (acq_run): Unable to find valid command list?\n');
    if(nargout > 0)
        varargout{1} = 1;
    end;
    return;
end;

if(~exist('DFILE', 'var') || isempty(DFILE))
    new('acq'); % make default acquisition
    e acq;
end

if(~exist('STIM2', 'var') || isempty(STIM2))
    STIM2 = new('steps');
    e 2; % display
end;

if(~exist('STIM', 'var') || isempty(STIM))
    new('steps');
    e stim; % display
end;

% Configure On-line analysis **************************************************
on_line('init', -1);  % (don't bring window up, just build global)
data=[];
first=1;

% create the rest of the window
acq_plot_data(-1, first, ONLINE, data, 0, DFILE);  % this will clear the acq_plot (-1)

set(h, 'KeyPressFcn', 'key_press');
% at this point, everything is driven by callbacks from the display window.

return;
