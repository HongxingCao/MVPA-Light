% Classifier unit test
%
% Classifier: lda

rng(42)
tol = 10e-10;
mf = mfilename;

% Random data
nfeatures = 100;
X = randn(1000, nfeatures);
clabel = randi(2, size(X,1),1);

%% check "scale" parameter: if scale = 1, training data should be scaled such that mean(class1)=1 and mean(class2)=-1

% Get classifier params
param = mv_get_classifier_param('lda');
param.scale = 1;

% Train and test classifier
cf = train_lda(param, X, clabel);
[~,dval] = test_lda(cf,X);

% Does class 1 project to +1 ?
print_unittest_result('check scale parameter for class 1',1, mean(dval(clabel==1)), tol);

% Does class 2 project to -1 ?
print_unittest_result('check scale parameter for class 2',-1, mean(dval(clabel==2)), tol);

%% check "prob" parameter: if prob = 1, probabilities should be returned as third parameter

% Get classifier params
param = mv_get_classifier_param('lda');
param.prob = 1;

% Train and test classifier
cf = train_lda(param, X, clabel);
[~,~,prob] = test_lda(cf,X);

% Are all returned values between 0 and 1?
print_unittest_result('check prob parameter',1, all(abs(prob)<=1),  tol);

%% check "lambda" parameter: if lambda = 1, w should be collinear with the difference between the class means

% Get classifier params
param = mv_get_classifier_param('lda');
param.reg       = 'shrink';
param.lambda    = 1;

cf = train_lda(param, X, clabel);

% Difference between class means
m = mean(X(clabel==1,:)) - mean(X(clabel==2,:));

% Correlation between m and cf.w
p = corr(m', cf.w);

% Are all returned values between 0 and 1?
print_unittest_result('check w parameter for lambda=1 (equal to diff of class means?)',1, p,  tol);

%% Equivalence between ridge and shrinkage regularisation

% Get classifier param for shrinkage regularisation
param_shrink = mv_get_classifier_param('lda');
param_shrink.reg   = 'shrink';
param_shrink.lambda = 0.5;

% Determine within-class scatter matrix (we need its trace)
Sw= sum(clabel==1) * cov(X(clabel==1,:),1) + sum(clabel==2) * cov(X(clabel==2,:),1);

% Determine the equivalent ridge parameter using the formula
% ridge = shrink/(1-shrink) * trace(C)/P
% Obviously the formula only works for shrink < 1
param_ridge = param_shrink;
param_ridge.reg      = 'ridge';
param_ridge.lambda   = param_shrink.lambda/(1-param_shrink.lambda) * trace(Sw)/nfeatures;

% Train classifiers with both types of regularisation
cf_shrink = train_lda(param_shrink, X, clabel);
cf_ridge = train_lda(param_ridge, X, clabel);

p = corr(cf_ridge.w, cf_shrink.w);

print_unittest_result('Corr between ridge and shrinkage classifier weights',1, p, tol);
