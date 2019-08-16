% mv_classify unit test

rng(42)
tol = 10e-10;
mf = mfilename;

% In the first part we will replicate behaviour of the other high-level
% functions (mv_classify_across_time, mv_classify_timextime,
% mv_crossvalidate, mv_searchlight) and compare their output to mv_classify
% output

%% compare to mv_crossvalidate
nsamples = 100;
nfeatures = 10;
nclasses = 2;
prop = [];
scale = 1;
do_plot = 0;
[X, clabel] = simulate_gaussian_data(nsamples, nfeatures, nclasses, prop, scale, do_plot);

% mv_crossvalidate
rng(42)
cfg = [];
cfg.feedback    = 0;
acc1 = mv_crossvalidate(cfg, X, clabel);

% mv_crossvalidate
rng(42)
cfg.sample_dimension = 1;
cfg.feature_dimension = 2;
acc2 = mv_classify(cfg, X, clabel);

print_unittest_result('compare to mv_crossvalidate', acc1, acc2, tol);

%% compare to mv_classify_across_time
nsamples = 50;
ntime = 100;
nfeatures = 10;
nclasses = 2;
prop = [];
scale = 0.0001;
do_plot = 0;

% Generate data
X2 = zeros(nsamples, nfeatures, ntime);
[~,clabel2] = simulate_gaussian_data(nsamples, nfeatures, nclasses, prop, scale, do_plot);

for tt=1:ntime
    X2(:,:,tt) = simulate_gaussian_data(nsamples, nfeatures, nclasses, prop, scale, do_plot);
end

% mv_classify_across_time
rng(21)   % reset rng to get the same random folds
cfg = [];
cfg.feedback = 0;
acc1 = mv_classify_across_time(cfg, X2, clabel2);

% mv_classify
rng(21)   % reset rng to get the same random folds
cfg.sample_dimension = 1;
cfg.feature_dimension = 2;
acc2 = mv_classify(cfg, X2, clabel2);

print_unittest_result('compare to mv_classify_across_time', 0, norm(acc1-acc2), tol);

%% compare to mv_classify_timextime

% mv_classify_timextime
rng(22)
cfg = [];
cfg.feedback = 0;
acc1 = mv_classify_timextime(cfg, X2, clabel2);

% mv_classify
rng(22)
cfg.sample_dimension = 1;
cfg.feature_dimension = 2;
cfg.generalization_dimension = 3;
acc2 = mv_classify(cfg, X2, clabel2);

print_unittest_result('compare to mv_classify_timextime', 0, norm(acc1-acc2), tol);

%% compare to mv_searchlight

% mv_classify_timextime
rng(22)
cfg = [];
cfg.feedback = 0;
acc1 = mv_searchlight(cfg, X, clabel);

% mv_classify
rng(22)
cfg.sample_dimension = 1;
acc2 = mv_classify(cfg, X, clabel);

print_unittest_result('compare to mv_searchlight', 0, norm(acc1-acc2), tol);

%% Create a dataset where classes can be perfectly discriminated for only some time points [two-class]
nsamples = 100;
ntime = 300;
nfeatures = 10;
nclasses = 2;
prop = [];
scale = 0.0001;
do_plot = 0;

can_discriminate = 50:100;
cannot_discriminate = setdiff(1:ntime, can_discriminate);

% Generate data
X = zeros(nsamples, nfeatures, ntime);
[~,clabel] = simulate_gaussian_data(nsamples, nfeatures, nclasses, prop, scale, do_plot);

for tt=1:ntime
    if ismember(tt, can_discriminate)
        scale = 0.0001;
        if tt==can_discriminate(1)
            [X(:,:,tt),~,~,M]  = simulate_gaussian_data(nsamples, nfeatures, nclasses, prop, scale, do_plot);
        else
            % reuse the class centroid to make sure that the performance
            % generalises
            X(:,:,tt)  = simulate_gaussian_data(nsamples, nfeatures, nclasses, prop, scale, do_plot, M);
        end
    else
        scale = 10e1; 
        X(:,:,tt) = simulate_gaussian_data(nsamples, nfeatures, nclasses, prop, scale, do_plot);
    end
end

cfg = [];
cfg.feedback = 0;
cfg.sample_dimension    = 1;
cfg.feature_dimension   = 2;
cfg.generalization_dimension   = 3;

[acc, result] = mv_classify(cfg, X, clabel);

% imagesc(acc), title(mf,'interpreter','none')
figure,imagesc(acc)

% performance should be around 100% for the discriminable time points, and
% around 50% for the non-discriminable ones
acc_discriminable = mean(mean( acc(can_discriminate, can_discriminate)));
acc_nondiscriminable = mean(mean( acc(cannot_discriminate, cannot_discriminate)));

tol = 0.03;
print_unittest_result('[two-class] CV discriminable times = 1?', 1, acc_discriminable, tol);
print_unittest_result('[two-class] CV non-discriminable times = 0.5?', 0.5, acc_nondiscriminable, tol);


%% Check different metrics and classifiers -- just run to see if there's errors (use 5 dimensions with 3 search dims)
X2 = randn(12, 5, 3, 4, 2);
clabel = ones(size(X2,1), 1); 
clabel(ceil(end/2):end) = 2;

cfg = [];
cfg.sample_dimension     = 1;
cfg.feature_dimension    = 2;
% % cfg.generalization_dimension = 4;
cfg.metric = 'acc';

cfg.feedback = 0;

for metric = {'acc','auc','f1','precision','recall','confusion','tval','dval'}
    for classifier = {'lda', 'logreg', 'multiclass_lda', 'svm', 'ensemble','kernel_fda','naive_bayes'}
        if any(ismember(classifier,{'kernel_fda' 'multiclass_lda','naive_bayes'})) && any(ismember(metric, {'tval','dval','auc'}))
            continue
        end
        fprintf('%s - %s\n', metric{:}, classifier{:})
        
        cfg.metric      = metric{:};
        cfg.classifier  = classifier{:};
        cfg.k           = 5;
        cfg.repeat      = 1;
        tmp = mv_classify(cfg, X2, clabel);
    end
end

%% Check different cross-validation types [just run to check for errors]

% 4 input dimensions with 2 search dims
sz = [8, 26, 5, 3];
X2 = randn(sz);

cfg = [];
cfg.sample_dimension     = 2;
cfg.feature_dimension    = 3;
cfg.generalization_dimension    = 1;
cfg.cv                   = 'kfold';
cfg.k                    = 2;
cfg.feedback             = 0;

clabel = ones(sz(cfg.sample_dimension), 1); 
clabel(ceil(end/2):end) = 2;

for cv = {'kfold' ,'leaveout', 'holdout', 'none'}
    fprintf('--%s--\n', cv{:})
    cfg.cv = cv{:};
    mv_classify(cfg, X2, clabel);
end

%% Check whether output dimensions are correct

% 4 input dimensions with 2 search dims
sz = [19, 2, 3, 40];
X2 = randn(sz);
clabel = ones(sz(1), 1); 
clabel(ceil(end/2):end) = 2;

cfg = [];
cfg.sample_dimension     = 1;
cfg.feature_dimension    = 3;
cfg.cv                   = 'kfold';
cfg.feedback             = 0;

perf = mv_classify(cfg, X2, clabel);
szp = size(perf);

print_unittest_result('is size(perf) correct for 4 input dimensions?', 0, norm(szp - sz([2,4])), tol);

% same but without cross-validation
cfg.cv                   = 'none';

perf = mv_classify(cfg, X2, clabel);
szp = size(perf);

print_unittest_result('[without crossval] is size(perf) correct for 4 input dimensions?', 0, norm(szp - sz([2,4])), tol);

%% 5 input dimensions with 2 search dims + 1 generalization dim - are output dimensions as expected?
sz = [11, 8, 9, 7, 6];
X2 = randn(sz);

cfg = [];
cfg.classifier              = 'lda';
cfg.hyperparameter          = [];
cfg.hyperparameter.lambda   = 0.1;
cfg.feedback                = 0;
cfg.cv                      = 'kfold';
cfg.k                       = 2;

% try out all possible positions for samples, generalization, and features

nd = ndims(X2);
for sd=1:nd   % sample dimension
    cfg.sample_dimension     = sd;
    clabel = ones(sz(sd), 1); 
    clabel(ceil(end/2):end) = 2;

    for ff=1:nd-1  % feature dimension
        fd = mod(sd+ff-1,nd)+1;
        cfg.feature_dimension    = fd;
        search_dim = setdiff(1:nd, [sd, fd]);
    
        for gg=1:nd-2   % generalization dimension
            gd = search_dim(gg);
            cfg.generalization_dimension = gd;
            search_dim_without_gen = setdiff(search_dim, gd);
            perf = mv_classify(cfg, X2, clabel);
            szp = size(perf);
            print_unittest_result(sprintf('[5 dimensions] sample dim %d, feature dim %d, gen dim %d', sd, fd, gd), 0, norm(szp - sz([search_dim_without_gen, gd ,gd])), tol);
        end
    end
end

