function obj = addNodeConstraint(obj, func, deps, nodes, lb, ub, type, auxdata)
    % Add NLP constraint function that only depends on variables at a
    % particular node. The input argument ''nodes'' will specify at which
    % nodes the function is defined.
    %
    % @note This function provides a simple type of constraints function which
    % dependends only on variables at same particular node. 
    %
    % @attention In the case the constraints function dependes on variables at
    % different nodes, please use the basic ''addCost'' method directly.
    %
    % @attention This method can be used to add any terminal constraint by
    % specify ''nodes'' as either ''first'' or ''last''.
    %
    % Parameters:
    % func: a symbolic function of the constraint @type SymFunction
    % deps: a list of dependent variables @type cellstr
    % node: an indicator of 'first' or 'last' node @type char
    % lb: the lower bound of the constraints @type colvec
    % ub: the upper bound of the constraints @type colvec
    % type: the type of the constraints (''Linear'' or ''Nonlinear'') @type char
    % auxdata: auxilary constant data to be feed in the function 
    % @type double
    
    
    % basic information of NLP decision variables
    nNode  = obj.NumNode;
    vars   = obj.OptVarTable;
    if ~iscell(deps), deps = {deps}; end
    
    validateattributes(func, {'SymFunction'},{'vector'},...
        'TrajectoryOptimization.addNodeConstraint','func');
    
    if nargin < 7
        type = 'Nonlinear';
    end

    if nargin < 8
        auxdata = [];
    else
        if ~iscell(auxdata), auxdata = {auxdata}; end
    end
    
    
    
    
    if ischar(nodes)
        switch nodes
            case 'first'
                node_list = 1;
            case 'last'
                node_list = nNode;
            case 'except-first'
                node_list = 2:nNode;
            case 'except-last'
                node_list = 1:nNode-1;
            case 'except-terminal'
                node_list = 2:nNode-1;
            case 'all'
                node_list = 1:nNode;
            case 'cardinal'
                node_list = 1:2:nNode;
            case 'interior'
                node_list = 2:2:nNode-1;
            otherwise
                error('Unknown node type.');
        end
    else
        if ~isnumeric(nodes)
            error(['The node must be specified as a list or following supported characters:\n',...
                '%s'],implode({'first','last','all','except-first','except-last','except-terminal', 'cardinal', 'interior'},','));
        else
            node_list = nodes;
        end
    end
    
    if lb == 0 && ub ==0 % equality constraints
        lb = -obj.Options.EqualityConstraintBoundary;
        ub = obj.Options.EqualityConstraintBoundary;
    end
    
    n_node = numel(node_list);
    cstr(n_node) = struct();
    [cstr.lb] = deal(lb);
    [cstr.ub] = deal(ub);
    [cstr.Type] = deal(type);
    [cstr.Name] = deal(func.Name);
    [cstr.SymFun] = deal(func);
    [cstr.AuxData] = deal(auxdata);
    for i=1:n_node
        idx = node_list(i);
        dep_vars = cellfun(@(x)vars.(x)(idx),deps,'UniformOutput',false);
        cstr(i).DepVariables = vertcat(dep_vars{:});
    end
    
    
    
    obj = addConstraint(obj,func.Name,nodes,cstr);
end