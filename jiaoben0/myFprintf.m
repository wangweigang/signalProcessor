function myFprintf(varargin)
%#eml

    % print based on first var: level of debug
    % this function can be called from embedded or normal m-script
    
    eml.extrinsic('fprintf');
    switch nargin
        case {0, 1}
            return;
        case 2
            levelDebug = varargin{1};
            if levelDebug == 0, return; end
            format2Print = varargin{2};
            fprintf(format2Print);
        case 3
            levelDebug = varargin{1};
            if levelDebug == 0, return; end
            format2Print = varargin{2};
            fprintf(format2Print, varargin{3});
        case 4
            levelDebug = varargin{1};
            if levelDebug == 0, return; end
            format2Print = varargin{2};
            fprintf(format2Print, varargin{3}, varargin{4});
        case 5
            levelDebug = varargin{1};
            if levelDebug == 0, return; end
            format2Print = varargin{2};
            fprintf(format2Print, varargin{3}, varargin{4}, varargin{5});
        case 6
            levelDebug = varargin{1};
            if levelDebug == 0, return; end
            format2Print = varargin{2};
            fprintf(format2Print, varargin{3}, varargin{4}, varargin{5}, varargin{6});
        case 7
            levelDebug = varargin{1};
            if levelDebug == 0, return; end
            format2Print = varargin{2};
            fprintf(format2Print, varargin{3}, varargin{4}, varargin{5}, varargin{6}, varargin{7});
        case 8
            levelDebug = varargin{1};
            if levelDebug == 0, return; end
            format2Print = varargin{2};
            fprintf(format2Print, varargin{3}, varargin{4}, varargin{5}, varargin{6}, varargin{7}, varargin{8});
        otherwise
            return;
    end