function [bs, x] = scr_bf_ldrf_gm(td, options)
% SCR_bf_ldrf_gm  
% Description: 
%
% FORMAT: [bs, x] = scr_bf_ldrf_gm(td, options) 
%     OR: [bs, x] = scr_bf_ldrf_gm(td)
%
%   Inputs:
%       td:         time resolution in s
%       options:    optional function paramters
%           duration:   duration of the function in s [20s]
%           offset:     offset in s. tells the function where to start with 
%                       the response function [0.2s]
%           params:     parameters for the gamma function. [default params 
%                       according to Korn et al.]
%
% with td = time resolution in s
%
% REFERENCE
%
%________________________________________________________________________
% PsPM 3.1
% (C) 2015 Tobias Moser (University of Zurich)

% $Id$   
% $Rev$
% initialise
global settings
if isempty(settings), scr_init; end;

% check input arguments
if nargin==0
    errmsg='No sampling interval stated'; warning(errmsg); return;
elseif nargin < 2
    options = struct();
end;

if ~isfield(options, 'params')
    options.params = [2.36014158356245,0.283916258442016,0.684370683567310];
end;

if ~isfield(options, 'duration')
    options.duration = 20;
end;

if ~isfield(options, 'offset')
    options.offset = 0.2;
end;

offset = options.offset;
bf_dur = options.duration;

n_bf = bf_dur/td;
bs = zeros(1, n_bf);
x2 = linspace(0,(bf_dur-offset)-td,(bf_dur-offset)/td);
x1 = linspace(0,offset-td,offset/td);
x = [x1, (x2+offset)];

% a: shape
% b: scale
% A: quantifier
p = options.params;
a = p(1);
b = p(2);
A = p(3);
gl = gammaln(a);

bs(round((offset+td)/td):end) = A * exp(log(x2).*(a-1) - gl - (x2)./b - log(b)*a);
