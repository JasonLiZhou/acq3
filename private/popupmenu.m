function [handle] = popupmenu(tag, label, callback, choices, fieldwidth, x, y)

% popupmenu.m - make a popupmenu with a label
% call: popupmenu (tag, label, initvalue, x, y)
% x and y are in character units...
% y+0.15???

b_ht = 1.5; % standard field height in characters
pad_static=4;
pad_popup=7;
fwtitle = length(label)+pad_static;
fontsz=10;
fwarg = fieldwidth+pad_popup;
h1 = uicontrol('Units','characters', ...
    'ListboxTop',0, ...
    'Position',[x y fwtitle b_ht], ...
    'HorizontalAlignment','left', ...
    'String',label, ...
    'Style','text', ...
    'FontSize', fontsz);
handle = uicontrol('Units','characters', ...
    'ListboxTop',0, ...
    'Position',[x+fwtitle y fwarg b_ht], ... 
    'Style','popupmenu', ...
    'Callback', callback, ...
    'Tag',tag);

set(handle, 'String', choices);
return
