function do_macro(mac)
%
global BASEPATH
global CONFIG IN_MACRO
if(IN_MACRO)
   QueMessage('Macro Already Running');
   return;
end;
olddir = cd(slash4OS([BASEPATH 'Macros']));
%try
   feval(mac)
   %catch
   %QueMessage(sprintf('Macro %s failed?', mac), 1);
   %IN_MACRO = 0;
   %end;
cd(olddir); % always return to original directory
return;

