function helpacq()
% help: display help information from contents.m in a new window
% ***CMD***
% The line above specifies this file as avaialable at the command line in
% acq3

global CMDS
hpf = findobj('Tag', 'AcqHelp'); % see if one exists...
if(isempty(hpf))
   hpf = figure( ...
      'name', 'AcqHelp', ...
      'Units', 'normalized', ...
      'Position', [0.1 0.1 0.8 0.8], ...
      'BackingStore', 'on', ...
      'NumberTitle', 'off', ...
      'Tag','pflist');
end;
figure(hpf);
clf;
hlist = uicontrol('Parent',hpf, ...
   'Units','normalized', ...
   'BackgroundColor','white', ...
   'ForegroundColor', 'black', ...
   'ListboxTop',1, ...
   'Position', [0.02 0.02 0.98 0.98], ...
   'HorizontalAlignment','left', ...
   'String','', ...
   'Style','ListBox', ...
   'FontSize', 8, ...
   'FontName', 'FixedWidth', ...
   'Tag','TheList');


[c, u] = sort(CMDS);
list = {};
for i = 1:length(c)
   list = cellcat(list, sprintf('%s', help(c{i})));
end;
set(hlist, 'String', list);

return;


function [o] = cellcat(in, string)
o = in;
p = length(in) + 1;
o{p} = string;
return;

fid = fopen('Contents.m', 'r');
x=[];
while(~feof(fid))
   x = [x fgetl(fid)];
end;
helpdlg(x);
return;
