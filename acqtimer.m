function acqtimer(obj, event)
u = getvalue(obj.Line(3:6));
putvalue(obj,[0 0 u]); % reset the dio's low
putvalue(obj,[1 1 u]); % reset the dio's high again...
