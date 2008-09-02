function fig = acq_main_screen()
% acq_main_screen: Generate the acquisition program main screen and controls
% PBManis 9/99
%
% 2/12/2001
% Altered uimenu list to allow access to common commands
global ACQVERSION ACQVERDATE
label = sprintf('Acq V%6.1f PBM %s', ACQVERSION, ACQVERDATE);

% We attempt to make a system independent display by
% using character spacing... this should allow the display to be correctly
% sized on windows, mac and unix systems, although the view may not be
% as pretty all the time
%
myinputbox = 1; %#ok<NASGU>

global BUTTONS DISPCTL

% adjust font size accordingn to system
% use 6 on windows,
% use 8 on mac/unix

switch(computer)
    case 'MAC'
        myfontsize = 8;
    case 'MACI'
        myfontsize = 10;
    case 'LNX'
        myfontsize=9;
    otherwise
        myfontsize = 8;
end;


% Button size definitions. These are not used in acq.
% But I leave them in just in case
b_ht = 1.7;
pad_check = 7; pad_edit = 5; pad_list = 5; pad_pop = 7;
pad_push = 4; pad_radio = 7; pad_static = 4;
but_vpad = 0.125;
but_hpad = 1;

but_vspc = b_ht + but_vpad; % space to allocate for each button or field

BUTTONS.b_ht = b_ht;
BUTTONS.pad_check = pad_check;
BUTTONS.pad_edit = pad_edit;
BUTTONS.pad_list = pad_list;
BUTTONS.pad_pop = pad_pop;
BUTTONS.pad_push = pad_push;
BUTTONS.pad_radio = pad_radio;
BUTTONS.pad_static = pad_static;
BUTTONS.vpad = but_vpad;
BUTTONS.hpad = but_hpad;
BUTTONS.vspc = but_vspc;


% build the button list (only 1 column of buttons in this version)
buttonlist = [];
buttonlist = add_button(buttonlist, 'Note', 'note', 'Make a Note', 'note', 'on', [], 'blue');
buttonlist = add_button(buttonlist, 'hrule');
buttonlist = add_button(buttonlist, 'PV', 'pv', 'Preview/Compute', 'pv', 'on', [], 'blue');
buttonlist = add_button(buttonlist, 'Scope', 'scope', 'Oscilloscope mode', 'scope', 'on', [], 'green');
buttonlist = add_button(buttonlist, 'STOP', 'acq_stop', 'Stop Acquisition', 'acq_stop', 'on', [], 'red');
buttonlist = add_button(buttonlist, 'hrule');
buttonlist = add_button(buttonlist, 'Take 1', 'take 1', 'Take one sample', 'take 1', 'on', [], [0.3 0.3 0.3]);
buttonlist = add_button(buttonlist, 'hrule');
buttonlist = add_button(buttonlist, 'VC-s', 'quick(1)', 'VClamp S mode', 'quick(1)', 'on', [], 'red');
buttonlist = add_button(buttonlist, 'VC-i', 'quick(2)', 'VClamp I mode', 'quick(2)', 'on', [], 'red');
buttonlist = add_button(buttonlist, 'CC-i', 'quick(3)', 'CClamp I mode', 'quick(3)', 'on', [], 'red');
%buttonlist = add_button(buttonlist, 'hrule');
buttonlist = add_button(buttonlist, 'VC-s2', 'quick(4)', 'VClamp Dual S mode', 'quick(4)', 'on', [], 'red');
buttonlist = add_button(buttonlist, 'VC-i2', 'quick(5)', 'VClamp Dual I mode', 'quick(5)', 'on', [], 'red');
buttonlist = add_button(buttonlist, 'CC-i2', 'quick(6)', 'CClamp Dual I mode', 'quick(6)', 'on', [], 'red');
buttonlist = add_button(buttonlist, 'hrule');
%buttonlist = add_button(buttonlist, 'Switch', 'sw', 'Switch mode', 'sw', 'on', [], 'blue');
%buttonlist = add_button(buttonlist, 'hrule');

buttonlist = add_button(buttonlist, 'X->X1', 'acq_cursormenu(''cxx1'')', 'cursor to online x1',...
    'acq_cursormenu(''cxx1'')', 'on', [], 'blue');
buttonlist = add_button(buttonlist, 'X->Y1', 'acq_cursormenu(''cxy1'')', 'cursor to online x2',...
    'acq_cursormenu(''cxy1'')', 'on', [], 'blue');
buttonlist = add_button(buttonlist, 'X->X2', 'acq_cursormenu(''cxx2'')', 'cursor to online y1',...
    'acq_cursormenu(''cxx2'')', 'on', [], 'blue');
buttonlist = add_button(buttonlist, 'X->Y2', 'acq_cursormenu(''cxy2'')', 'cursor to online y2',...
    'acq_cursormenu(''cxy2'')', 'on', [], 'blue');
%buttonlist = add_button(buttonlist, 'hrule');
buttonlist = add_button(buttonlist, 'Y->Y1', 'acq_cursormenu(''cy1'')', 'cursor to online y1',...
    'acq_cursormenu(''cy1'')', 'on', [], 'blue');
buttonlist = add_button(buttonlist, 'Y->Y2', 'acq_cursormenu(''cy2'')', 'cursor to online y2',...
    'acq_cursormenu(''cy2'')', 'on', [], 'blue');


grctllist = []; % build graphic button control list - display control
grctllist = add_button(grctllist, 'pos up', '', 'zero position up', ...
    'acq_d_select', 'on', [], 'black', '1|2|3|4|5|6|7|8');
grctllist = add_button(grctllist, 'hrule');
grctllist = add_button(grctllist, 'Pos', 'chdis()', 'zero position', ...
    'acq_d_position', 'on', [], 'black', '100|90|80|70|60|50|40|30|20|10|0');
grctllist = add_button(grctllist, 'Gain', 'chdis()', 'gain', ...
    'acq_d_gain', 'on', [], 'black', '1|2|5|10|20|50|100|200|500|1000|2000|5000|10000|20000|40000');
grctllist = add_button(grctllist, 'hrule');
grctllist = add_button(grctllist, '2 Ch', 'default_display(0)', '2 Ch default', ...
    'dtwo', 'on', [], 'black');
grctllist = add_button(grctllist, '3 Ch', 'default_display(4)', '3 Ch default', ...
    'dthree', 'on', [], 'black');
grctllist = add_button(grctllist, '4 Ch', 'default_display(5)', '4 Ch Default', ...
    'dfour', 'on', [], 'black');
grctllist = add_button(grctllist, 'CC Spk', 'default_display(2)', 'CC Spiking', ...
    'dccspike', 'on', [], 'black');
grctllist = add_button(grctllist, 'CC EPSP', 'default_display(3)', 'CC EPSP', ...
    'dccepsp', 'on', [], 'black');
grctllist = add_button(grctllist, 'Zoom  ', 'acq_cursormenu(''zoom'')', 'Zoom graph', 'acq_cursormenu(''zoom'')', 'on', [], 'blue');
grctllist = add_button(grctllist, 'Unzoom', 'acq_cursormenu(''restore'')', 'Normal scaling for graph', ...
    'acq_cursormenu(''restore'')', 'on', [], 'blue');

maxctlwid = 0;
for i = 1:length(grctllist)
    l = length(grctllist(i).title);
    if(l > maxctlwid)
        maxctlwid = l;
    end;
end;

grctl_width = maxctlwid+4*but_hpad;
GRCTL.width = grctl_width;
GRCTL.buttonlist = grctllist;

maxtitle = 0;
for i=1:length(buttonlist)
    l = length(buttonlist(i).title);
    if(l > maxtitle)
        maxtitle = l;
    end
end
but_width = maxtitle+4*but_hpad;

BUTTONS.width = but_width;
BUTTONS.buttonlist = buttonlist;

set(0, 'units', 'pixels');
scrsz = get(0,'ScreenSize'); % determine the position of the figure in the system window

if(scrsz(3) > 1280)
    scrsz = [0 0 1280 1024];
end;

scrb = 32;
scrl = 1;
scrwd = scrsz(3)-1;
scrht = scrsz(4)-70;
% create the main window
% Our goal is that this will be the ONLY window. No floaters.
h0 = figure('name', 'ACQ: Data Acquisition', ...
    'NumberTitle', 'off', ...
    'Color', [0. 0. 0.], ...
    'Colormap',[1,1,1], ...
    'Position', [scrl, scrb, scrwd, scrht], ...
    'CloseRequestFcn', 'bye', ...
    'KeyPressFcn', @key_press, ...
    'MenuBar', 'none', ...
    'WindowButtonMotionFcn', 'acq3(''mouse_motion'', gcbf);', ...
    'WindowButtonDownFcn', 'acq3(''mouse_down'', gcbf);', ...
    'WindowButtonUpFcn', 'acq3(''mouse_up'', gcbf);', ...
    'Tag','Acq');
set(h0, 'Units', 'characters');
set(gcf,'Renderer','OpenGL');
figsz=get(h0, 'Position');

button_x = 1; % figsz(3) - but_width-but_hpad;  % place the buttons to the left side of the display
button_y = figsz(4)-1;

BUTTONS.x = button_x;
BUTTONS.y = button_y;

% define the command window - its a one line wonder
mat_win = 5; % space for the matlab window to set
que_win = mat_win + 1;
finfo_win = que_win + 2.1; % space for the file info to set
ampinfo_win = finfo_win+1.4;

frame_win = ampinfo_win + 2.1; % space for the frame to set
cmdbox_x = but_width + but_hpad+1.5;
%cmdbox_y = figsz(4)-(ampinfo_win+1); % space for the  command box to set
cmd_width = 72; % width in characters
cmd_border = 0.2;

backcolor=[0 0 0];
f_ht=(b_ht+but_vpad)*20;
frame_right=cmd_width+cmdbox_x*2*cmd_border;

%listbox_x=0.6;
%listbox_y = figsz(4)*0.6;

top=figsz(4);
%topb = figsz*0.75;

% first set up the "command area" -
% Also the Que message, drive and default extension
% gain selection, and record number areas

% Make a general background frame for the information area

uicontrol('Parent',h0, ...
    'Units','characters', ...
    'BackgroundColor',backcolor, ...
    'ForegroundColor', 'black', ...
    'ListboxTop',0, ...
    'Position',[cmdbox_x-cmd_border top-f_ht-cmd_border frame_right+cmd_border*2 f_ht+cmd_border*2], ...
    'HorizontalAlignment','left', ...
    'Style','frame', ...
    'visible', 'off', ...
    'Tag','Fileframe');

if(exist('myinputbox', 'var')) % use matlab command window, docked in the same space.
    uicontrol('Parent',h0, ...
        'Units','characters', ...
        'BackgroundColor','white', ...
        'ForegroundColor', 'black', ...
        'ListboxTop',1, ...
        'Position',[cmdbox_x top - 2 cmd_width 1.1*b_ht], ...
        'HorizontalAlignment','left', ...
        'String','', ...
        'TooltipString', 'Command Window', ...
        'Style','edit', ...
        'Callback', 'command_parse;', ...
        'FontSize', myfontsize, ...
        'Tag','InputBox');
else
    uicontrol('Parent',h0, ...
        'Units','characters', ...
        'BackgroundColor','white', ...
        'ForegroundColor', 'blue', ...
        'ListboxTop',1, ...
        'Position',[cmdbox_x top - mat_win cmd_width top - 1], ...
        'HorizontalAlignment','left', ...
        'String','', ...
        'TooltipString', 'Dock Matlab Window Here ', ...
        'Style','edit', ...
        'FontSize', myfontsize+2, ...
        'Tag','InputBox');
end;

% now the Que Message Window (2 lines)
% Note that we make this box TEXT so that clicking on it doesn't cause problems
uicontrol('Parent',h0, ...
    'Units','characters', ...
    'BackgroundColor',[0.3 0.3 0.3], ...
    'ForegroundColor', 'white', ...
    'ListboxTop',1, ...
    'Position',[cmdbox_x top - que_win cmd_width 2*b_ht], ...
    'HorizontalAlignment','left', ...
    'String','', ...
    'TooltipString', 'Information Window', ...
    'Style','text', ...
    'FontSize', myfontsize, ...
    'Tag','QueMessage');

% panel for text about current configuration
hp = uipanel('Parent',h0, ...
    'Units','characters', ...
    'BorderType', 'line', ...
    'BackgroundColor',[0 0 0], ...
    'ForegroundColor', [0 0 1]', ...
    'Position',[cmdbox_x+1 1.2 cmd_width 8.7], ...
    'FontSize', myfontsize, ...
    'Tag','ConfigInfoFrame');
% box for text about current configuration
uicontrol('Parent',hp, ...
    'Units','characters', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'ForegroundColor', [0 0 0]', ...
    'ListboxTop',0, ...
    'Position', [0.1 0.1 cmd_width-2*0.1 8.7-2.5*0.1], ...
    'HorizontalAlignment','left', ...
    'String','', ...
    'TooltipString', 'Configuration Information', ...
    'Style','text', ...
    'FontSize', myfontsize, ...
    'Tag','ConfigInfo');




% simple text box for the current filename.
uicontrol('Parent', h0, ...
    'Units', 'characters', ...
    'BackgroundColor', [0.25 0.25 0.6], ...
    'ForegroundColor', [1 1 0], ...
    'Position', [cmdbox_x+9, top - finfo_win, 28, 1.33], ...
    'HorizontalAlignment','left', ...
    'String','<closed>', ...
    'Style', 'text', ...
    'Tag', 'DispFilename');
uicontrol('Parent', h0, ...
    'Units', 'characters', ...
    'BackgroundColor', [0.25 0.25 0.25], ...
    'ForegroundColor', [1 1 1], ...
    'Position', [cmdbox_x, top - finfo_win, 8, 1.33], ...
    'HorizontalAlignment','left', ...
    'String','File', ...
    'Style', 'text', ...
    'Tag', 'DispFilet');

% simple text box for the Amp status.
uicontrol('Parent', h0, ...
    'Units', 'characters', ...
    'BackgroundColor', [0.25 0.25 0.6], ...
    'ForegroundColor', [1 1 0], ...
    'Position', [cmdbox_x+9, top - ampinfo_win-0.666, 32, 2.00], ...
    'HorizontalAlignment','left', ...
    'String',' ', ...
    'Style', 'text', ...
    'Tag', 'AmpStatus');

uicontrol('Parent', h0, ...
    'Units', 'characters', ...
    'BackgroundColor', [0.25 0.25 0.25], ...
    'ForegroundColor', [1 1 1], ...
    'Position', [cmdbox_x, top - ampinfo_win, 8, 1.33], ...
    'HorizontalAlignment','left', ...
    'String','Amplifier', ...
    'Style', 'text', ...
    'Tag', 'AmpStatust');

%Simple text box for Block Number

uicontrol('Parent', h0, ...
    'Units', 'characters', ...
    'BackgroundColor', [0.25 0.25 0.25], ...
    'ForegroundColor', [1 1 1], ...
    'Position', [cmdbox_x+42, top - finfo_win, 8, 1.33], ...
    'HorizontalAlignment','left', ...
    'String','Block', ...
    'Style', 'text', ...
    'Tag', 'Blockt');
uicontrol('Parent', h0, ...
    'Units', 'characters', ...
    'BackgroundColor', [0.25 0.25 0.6], ...
    'ForegroundColor', [1 1 0], ...
    'Position', [cmdbox_x+50, top - finfo_win, 16, 1.33], ...
    'HorizontalAlignment','left', ...
    'String',' ', ...
    'Style', 'text', ...
    'Tag', 'Blockn');


% simple text box for Record number
uicontrol('Parent', h0, ...
    'Units', 'characters', ...
    'BackgroundColor', [0.25 0.25 0.25], ...
    'ForegroundColor', [1 1 1], ...
    'Position', [cmdbox_x+42, top - ampinfo_win, 8, 1.33], ...
    'HorizontalAlignment','left', ...
    'String','Record', ...
    'Style', 'text', ...
    'Tag', 'Recnt');

uicontrol('Parent', h0, ...
    'Units', 'characters', ...
    'BackgroundColor', [0.25 0.25 0.6], ...
    'ForegroundColor', [1 1 0], ...
    'Position', [cmdbox_x+50, top - ampinfo_win, 16, 1.33], ...
    'HorizontalAlignment','left', ...
    'String',' ', ...
    'Style', 'text', ...
    'Tag', 'Recn');

%----------------------------------------
% Vertical Separation between text and graphics...
uicontrol('Parent',h0, ...
    'Units','characters', ...
    'BackgroundColor',[0.05 0.05 0.2], ...
    'ForegroundColor', [1 1 1], ...
    'ListboxTop',0, ...
    'Position',[cmdbox_x+cmd_width+2 0 0.5 button_y+1], ...
    'HorizontalAlignment','left', ...
    'Style','frame', ...
    'visible', 'on', ...
    'Tag','AcqCenterBorder');


%--------------
% command buttons are here
% first group is left hand side controlling acquisition etc.
% below that is the group that loads info into the online analysis
% parameters

cmd_vspc = but_vspc + 2*but_vpad; % extra padding
% frame behind buttons...
uicontrol('Parent',h0, ...
    'Units','characters', ...
    'BackgroundColor',[0.05 0.05 0.2], ...
    'ForegroundColor', [1 1 1], ...
    'ListboxTop',0, ...
    'Position',[button_x-1 0 but_width+2 button_y+1], ...
    'HorizontalAlignment','left', ...
    'Style','frame', ...
    'Tag','ButtonBorder');

b_y = button_y;
for i=1:length(buttonlist)
    if(strcmp(buttonlist(i).title, 'hrule')) % ruler bars
        b_y = b_y - cmd_vspc*0.75;
        uicontrol('Parent', h0, ...
            'Units', 'characters', ...
            'BackgroundColor', [0 0 1], ...
            'Enable', 'off', ...
            'Position', [button_x b_y but_width+0.5 b_ht*0.1]);
        b_y = b_y - cmd_vspc * 0.25;
    else

        b_y = b_y - cmd_vspc;

        uicontrol('Parent', h0, ...
            'Units', 'characters', ...
            'FontUnits', 'points', ...
            'FontName', 'Arial', ...
            'FontSize', myfontsize+1, ...
            'ForegroundColor', buttonlist(i).color, ...
            'Position', [button_x b_y but_width+0.5 b_ht], ...
            'String', buttonlist(i).title, ...
            'ToolTipString', buttonlist(i).tooltip, ...
            'Callback', buttonlist(i).callback, ...
            'Enable', buttonlist(i).enable, ...
            'Tag', buttonlist(i).tag);
    end
end

%----- graphics control buttons...
% these set up the graphic display windows for the data itself...

hwid = figsz(3) - cmd_width - 27;
lhs = cmdbox_x + cmd_width + 3;
gbutton_x = hwid+lhs; %  % place the buttons to the right side of the display
gbutton_y = figsz(4)*0.5; % middle of right side...

b_y = gbutton_y;
for i=1:length(grctllist)
    if(strcmp(grctllist(i).title, 'hrule'))
        b_y = b_y - cmd_vspc*0.75;
        uicontrol('Parent', h0, ...
            'Units', 'characters', ...
            'BackgroundColor', [0 0 1], ...
            'Enable', 'off', ...
            'Position', [gbutton_x b_y but_width+0.5 b_ht*0.1]);
        b_y = b_y - cmd_vspc * 0.15;
    else

        b_y = b_y - cmd_vspc;

        if(~isempty(grctllist(i).strlist))
            uicontrol('Parent', h0, ...
                'Units', 'characters', ...
                'FontUnits', 'points', ...
                'FontName', 'Arial', ...
                'FontSize', myfontsize, ...
                'ForegroundColor', grctllist(i).color, ...
                'Position', [gbutton_x b_y but_width+0.5 b_ht], ...
                'Style', 'popup', ...
                'Value', 1, ...
                'String', grctllist(i).strlist, ...
                'ToolTipString', grctllist(i).tooltip, ...
                'Callback', grctllist(i).callback, ...
                'Enable', grctllist(i).enable, ...
                'Tag', grctllist(i).tag);
        else

            uicontrol('Parent', h0, ...
                'Units', 'characters', ...
                'FontUnits', 'points', ...
                'FontName', 'Arial', ...
                'FontSize', myfontsize, ...
                'ForegroundColor', grctllist(i).color, ...
                'Position', [gbutton_x b_y but_width+0.5 b_ht], ...
                'String', grctllist(i).title, ...
                'ToolTipString', grctllist(i).tooltip, ...
                'Callback', grctllist(i).callback, ...
                'Enable', grctllist(i).enable, ...
                'Tag', grctllist(i).tag);
        end;
    end
end

%--------
uicontrol('Units','characters', ...
    'BackgroundColor',[0 0 0], ...
    'ForegroundColor', [1 1 1], ...
    'ListboxTop',0, ...
    'Position',[cmdbox_x+1 0 length(label)+5 1], ...
    'HorizontalAlignment','left', ...
    'String',label, ...
    'Style','text', ...
    'FontSize', myfontsize);

%
% Frames for the parameters (these are not just to look pretty...
%  The user data for the frame should contain the array of handles to
% the objects contained in the frame. This is the responsibility of the programmer)
% Frames are accessed by the struct_edit routine
%
frame_w = 72; frame_h = top-frame_win;
frame_bot = 10;
frame_h = frame_h-frame_bot;
hfm = uicontrol('Parent',h0, ...
    'Units','characters', ...
    'BackgroundColor',[0 0 0], ...
    'ForegroundColor', [0 0 1], ...
    'ListboxTop',0, ...
    'Position',[cmdbox_x+1 frame_bot  frame_w frame_h], ...
    'HorizontalAlignment','left', ...
    'Style','frame', ...
    'Visible', 'off', ...
    'Tag','FMaster');

fl.hf(1) = uicontrol('Parent',h0, ...
    'Units','characters', ...
    'BackgroundColor',[0 0 0], ...
    'ForegroundColor', [0 0 1], ...
    'ListboxTop',0, ...
    'Position',[cmdbox_x+1 frame_bot  frame_w frame_h], ...
    'HorizontalAlignment','left', ...
    'Style','frame', ...
    'Visible', 'on', ...
    'Tag','FStim');

fl.hf(2) = uicontrol('Parent',h0, ...
    'Units','characters', ...
    'BackgroundColor',[0 0 0], ...
    'ForegroundColor', [0 0 1], ...
    'ListboxTop',0, ...
    'Position',[cmdbox_x+1 frame_bot  frame_w frame_h], ...
    'HorizontalAlignment','left', ...
    'Style','frame', ...
    'Visible', 'off', ...
    'Tag','FDfile');

fl.hf(3) = uicontrol('Parent',h0, ...
    'Units','characters', ...
    'BackgroundColor',[0 0 0], ...
    'ForegroundColor', [0 0 1], ...
    'ListboxTop',0, ...
    'Position',[cmdbox_x+1 frame_bot  frame_w frame_h], ...
    'HorizontalAlignment','left', ...
    'Style','frame', ...
    'Visible', 'off', ...
    'Tag','FConfig');

fl.vis = 1;
set(hfm, 'UserData', fl); % store frames in user space in invisible master frame

%
% Frames for the plotted data and preview.
%
hwid = figsz(3) - cmd_width - 27;
lhs = cmdbox_x + cmd_width + 3;

uicontrol('Parent',h0, ...
    'Units','characters', ...
    'BackgroundColor',[0 0 0], ...
    'ForegroundColor', [0 0 1], ...
    'ListboxTop',0, ...
    'Position',[lhs button_y*0.85+1  hwid button_y*0.15-1], ...
    'HorizontalAlignment','left', ...
    'Style','frame', ...
    'visible', 'off', ...
    'Tag','UtilityFrame');


uicontrol('Parent',h0, ...
    'Units','characters', ...
    'BackgroundColor',[0 0 0], ...
    'ForegroundColor', [0 0 1], ...
    'ListboxTop',0, ...
    'Position',[lhs button_y*0.65+1  hwid button_y*0.2-1], ...
    'HorizontalAlignment','left', ...
    'Style','frame', ...
    'Tag','OLAFrame');
uicontrol('Parent',h0, ...
    'Units','characters', ...
    'BackgroundColor',[0 0 0], ...
    'ForegroundColor', [0 0 1], ...
    'ListboxTop',0, ...
    'Position',[lhs 1  hwid button_y*0.65-1], ...
    'HorizontalAlignment','left', ...
    'Style','frame', ...
    'Tag','DataFrame');


%_________________________________________________________
%
% now build the menu entries.....
% These access the most commonly used routines
%
f = uimenu('Label', '&File', 'Position', 1);
uimenu(f, 'Label', '&Open', 'Callback', 'aopen;');
uimenu(f, 'Label', '&Close', 'Callback', 'ac;');
uimenu(f, 'Label', '&Configuration', 'Callback', 'gc');
uimenu(f, 'Label', '&Hardware reload', 'Callback', 'gh(''find'')');
uimenu(f, 'Label', '&Gather Commands', 'Callback', 'command_gather;');
uimenu(f, 'Label', '&TestMode', 'Callback', 'set_testmode');
uimenu(f, 'Label', '&Exit', 'Callback', 'bye;', 'Separator', 'On');

% Edit - access the parameter blocks
f = uimenu('Label','&Edit', 'Position', 2);
uimenu(f,'Label','Edit Acquisition','Callback','e a;');
uimenu(f,'Label','Edit Stimulus','Callback','e s;' );
uimenu(f,'Label', 'Edit Pulse', 'Callback', 'pulse_edit;'); % special
uimenu(f,'Label', 'Edit Alpha', 'Callback', 'alpha_edit;'); % special
%uimenu(f,'Label','Edit Configuration','Callback','e c;');
uimenu(f, 'Label', 'Save Current Protocol', 'Callback', 's;', 'Separator', 'On');
%uimenu(f, 'Label', 'Save Current Configuration', 'Callback', 'sc;', 'Separator', 'Off');
%uimenu(f, 'Label', 'New STIMULUS (clears!)', 'Callback', 'new clear;', 'Separator', 'On');
%uimenu(f, 'Label', 'Delete Current Stimulus element', 'Callback', 'struct_edit(''delete'', 0);', 'Separator', 'Off');
uimenu(f,'Label','New &Steps','Callback','new steps;' , 'Separator', 'On');
uimenu(f,'Label','New &Pulse','Callback','new pulse;' );
uimenu(f,'Label','New &Ramp', 'Callback','new ramp;' );
uimenu(f,'Label','New &Alpha','Callback','new alpha;' );
uimenu(f,'Label','New &Noise','Callback','new noise;' );
uimenu(f,'Label','New S&ine','Callback','new sine;' );
uimenu(f,'Label','New &TestPulse','Callback','new testpulse;' );
uimenu(f,'Label','New Au&dNerve','Callback','new audnerve;' );
uimenu(f,'Label','New AN&FS (JSR)', 'Callback', 'new anf;');
uimenu(f,'Label','New P&oisson', 'Callback', 'new poisson;');



f = uimenu('Label', '&Protocols', 'Position', 3, 'Tag', 'ProtocolMain');
menu_protocols(f); % gather the protocols and store in this menu list

f = uimenu('Label', '&Macros', 'Position', 4, 'Tag', 'MacroMain');
menu_macros(f);

f = uimenu('Label', '&Acquisition', 'Position', 5);
uimenu(f, 'Label', '&Sequence', 'Callback', 'seq;', 'Accelerator', 'a');
uimenu(f, 'Label', '&Data', 'Callback', 'acquire_one data;', 'Accelerator', 'd');
uimenu(f, 'Label', 'S&cope', 'Callback', 'scope;', 'Separator', 'On', 'Accelerator', 'o');
uimenu(f, 'Label', 'S&top', 'Callback', 'acq_stop;', 'Accelerator', 's');
uimenu(f, 'Label', 'S&witch', 'Callback', 'switch;', 'Accelerator', 'w');
uimenu(f, 'Label', '&GapFree', 'Callback', 'gapfree;', 'Separator', 'On', 'Accelerator', 'g');

f = uimenu('Label', '&Display', 'Position', 6);
uimenu(f, 'Label', 'Display &Control', 'Callback', 'displayctl;');
uimenu(f, 'Label', '&Erase', 'Callback', 'er;', 'Accelerator', 'e');
uimenu(f, 'Label', '&V display', 'Callback', 'vdis;', 'Separator', 'On');
uimenu(f, 'Label', '&I display', 'Callback', 'idis;');
uimenu(f, 'Label', '&2-chan Default', 'Callback', 'default_display(0);');
uimenu(f, 'Label', 'CC-&Spiking', 'Callback', 'default_display(2);');
uimenu(f, 'Label', 'CC-&EPSP', 'Callback', 'default_display(3);');
uimenu(f, 'Label', '&3-chan Default', 'Callback', 'default_display(4);');
uimenu(f, 'Label', '&4-chan Default', 'Callback', 'default_display(5);');
uimenu(f, 'Label', 'CH1 display', 'Callback', 'chdis(1);', 'Separator', 'On');
uimenu(f, 'Label', 'CH2 display', 'Callback', 'chdis(2);');
uimenu(f, 'Label', 'CH3 display', 'Callback', 'chdis(3);');
uimenu(f, 'Label', 'CH4 display', 'Callback', 'chdis(4);');
uimenu(f, 'Label', 'CH5 display', 'Callback', 'chdis(5);');
uimenu(f, 'Label', 'CH6 display', 'Callback', 'chdis(6);');
uimenu(f, 'Label', 'CH7 display', 'Callback', 'chdis(7);');
uimenu(f, 'Label', 'CH8 display', 'Callback', 'chdis(8);');


f = uimenu('Label', '&Analyses', 'Position', 7);
uimenu(f, 'Label', '&Online Analysis', 'Callback', 'on_line(''up'');', 'Separator', 'Off');
hf=uimenu(f, 'Label', '&Utility Plot', 'Callback', 'toggleutility;', 'Separator', 'On', 'tag', 'menu_utility');
if(isempty(DISPCTL))
    initdispctl;
end;
if(DISPCTL.utility == 1)
    set(hf, 'checked', 'on');
else
    set(hf, 'checked', 'off');
end;

f = uimenu('Label', '&Model', 'Position', 8);
uimenu(f, 'Label', 'Type I-c', 'Callback', 'acq_model(1)');
uimenu(f, 'Label', 'Type I-t', 'Callback', 'acq_model(2)');
uimenu(f, 'Label', 'Type I-II', 'Callback', 'acq_model(3)');
uimenu(f, 'Label', 'Type II-I', 'Callback', 'acq_model(4)');
uimenu(f, 'Label', 'Type II', 'Callback', 'acq_model(5)');
uimenu(f, 'Label', 'Type II-o', 'Callback', 'acq_model(6)');
uimenu(f, 'Label', 'Type Pyr', 'Callback', 'acq_model(7)');

f = uimenu('Label','&Help', 'Position', 9);
uimenu(f, 'Label', 'Help', 'Callback', 'helpacq');
uimenu(f, 'Label', 'Show Flags', 'Callback', 'clear_flags(1)');
uimenu(f, 'Label', 'Clear Flags (Caution!)', 'Callback', 'clear_flags(2)');

if (nargout > 0)
    fig = h0;
end;



