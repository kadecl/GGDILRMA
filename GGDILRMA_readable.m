function [S, cost, W] = GGDILRMA_readable(X, type, It, nb, drawConv)
% Independent low-rank matrix analysis (ILRMA)
%
% Coded by D. Kitamura (d-kitamura@ieee.org)
%
% Copyright 2018 Daichi Kitamura
%
% These programs are distributed only for academic research at
% universities and research institutions.
% It is not allowed to use or modify these programs for commercial or
% industrial purpose without our permission.
% When you use or modify these programs and write research articles,
% cite the following references:
%
% # Original paper (The algorithm was called "Rank-1 MNMF" in this paper)
% D. Kitamura, N. Ono, H. Sawada, H. Kameoka, H. Saruwatari, "Determined
% blind source separation unifying independent vector analysis and
% nonnegative matrix factorization," IEEE/ACM Trans. ASLP, vol. 24,
% no. 9, pp. 1626-1641, September 2016.
%
% # Book chapter (The algorithm was renamed as "ILRMA")
% D. Kitamura, N. Ono, H. Sawada, H. Kameoka, H. Saruwatari, "Determined
% blind source separation with independent low-rank matrix analysis,"
% Audio Source Separation. Signals and Communication Technology.,
% S. Makino, Ed. Springer, Cham, pp. 125-155, March 2018.
%
% See also:
% http://d-kitamura.net
% http://d-kitamura.net/demo-ILRMA_en.html
%
% [syntax]
%   [Y, cost, W] = ILRMA(X)
%   [Y, cost, W] = ILRMA(X, type)
%   [Y, cost, W] = ILRMA(X, type, It)
%   [Y, cost, W] = ILRMA(X, type, It, nb)
%   [Y, cost, W] = ILRMA(X, type, It, nb, drawConv)
%   [Y, cost, W] = ILRMA(X, type, It, nb, drawConv, normalize)
%
% [inputs]
%          X: input multichannel signals in time-frequency domain (frequency bin x time frame x channel)
%       type: 1 or 2 (1: ILRMA without partitioning function (ILRMA1), 2: ILRMA with partitioning function (ILRMA2), default: 1)
%         It: number of iterations (default: 100)
%         nb: number of bases for each source in ILRMA1, or number of bases for all the sources in ILRMA2 (default: time frames/10)
%   drawConv: calculate values of cost function in each iteration for drawing convergence curve or not (true or false, default: false)
%  normalize: normalize variables in each iteration to avoid numerical divergence or not (true or false, default: true, normalization may collapse monotonic decrease of the cost function)
%
% [outputs]
%          Y: estimated multisource signals in time-frequency domain (frequency bin x time frame x source)
%       cost: values of cost function in each iteration (It+1 x 1)
%          W: demixing matrices (source x channel x frequency bin)
%

% Check errors and set default values
narginchk(1,5)

[I,J,M] = size(X);
N = M;
if (N > I)
    error('The input spectrogram might be wrong. The size of it must be (freq x frame x ch).\n');
end
if (nargin < 2)
    type = 1; % use ILRMA1 (fixed number of bases for each source)
end
if (nargin < 3)
    It = 100;
end
if (nargin < 4)
    nb = ceil(J/10);
end
if (type == 1)
    L = nb; % number of bases for each source in ILRMA1
elseif (type == 2)
    K = nb; % number of bases for all the sources in ILRMA2
else
    error('The input argument "type" must be 1 or 2.\n');
end
if (nargin < 5)
    drawConv = false;
end

    W = zeros(N,M,I);
    for i=1:I
        W(:,:,i) = eye(N); % initial demixing matrices (identity matrices)
    end

    if (type == 1)
        T = max( rand( I, L, N ), eps ); % initial basis matrix in ILRMA1
    elseif (type == 2)
        T = max( rand( I, K ), eps ); % initial basis matrix in ILRMA2
    end

    if (type == 1)
        V = max( rand( L, J, N ), eps ); % initial activation matrix in ILRMA1
    elseif (type == 2)
        V = max( rand( K, J ), eps ); % initial activation matrix in ILRMA2
    end

if size(W,1) ~= N || size(W,2) ~= M || size(W,3) ~= I
    error('The size of input initial W is incorrect.\n');
end
if (type == 1)
    if (size(T,1) ~= I || size(T,2) ~= L || size(V,1) ~= L || size(V,2) ~= J)
        error('The sizes of input initial T and V are incorrect.\n');
    end
else
    if (size(T,1) ~= I || size(T,2) ~= K || size(V,1) ~= K || size(V,2) ~= J)
        error('The sizes of input initial T and V are incorrect.\n');
    end
end

% Initialization
beta = 3;
rho = beta;
R = zeros(I,J,N);
L = zeros(I,J,N);
S = zeros(I,J,N);
H = zeros(N,J);

for i=1:I
    S(i,:,:) = ( squeeze(W(:,:,i)) * squeeze(X(i,:,:)).').'; % initial estimated signals
end
P = max(abs(S).^beta,eps); %power
E = eye(N); %単位行列
Xp = permute(X,[3,2,1]); % M x J x I
cost = zeros(It+1,1);

type = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%% ILRMA1 %%%%%%%%%%%%%%%%%%%%%%%%%%%
if (type==1) % Algorithm for ILRMA1
    for n=1:N
        R(:,:,n) = T(:,:,n)*V(:,:,n); % source model
    end
    if drawConv
        cost(1,1) = costFunction_local( P, R, W, I, J, N, beta );
    end
    % Iterative update
    fprintf('Iteration:    ');
    for it=1:It
        fprintf('\b\b\b\b%4d', it);
        for n=1:N
            %%%%% Update T %%%%%
            T(:,:,n) = T(:,:,n) .* ( beta * squeeze(P(:,:,n).*(R(:,:,n).^(-1-beta/rho)))*squeeze(V(:,:,n)).' ...
                ./ ( 2*(R(:,:,n).^(-1)) * V(:,:,n).' ) ).^( rho/(beta+rho) );
            T(:,:,n) = max(T(:,:,n),eps);
            R(:,:,n) = squeeze(T(:,:,n))*squeeze(V(:,:,n));
            %%%%% Update V %%%%%
            V(:,:,n) = V(:,:,n) .* ( beta * T(:,:,n).'*(P(:,:,n).*(R(:,:,n).^(-1-beta/rho))) ...
                ./ ( 2*T(:,:,n).' * (R(:,:,n).^(-1)) ) ).^( rho/(beta+rho) );
            V(:,:,n) = max(V(:,:,n),eps);
            R(:,:,n) = squeeze(T(:,:,n)) * squeeze(V(:,:,n));
            %%%%% Update L %%%%%
            L(:,:,n) = ( S(:,:,n).^(4-beta) .* R(:,:,n).^ beta ).^(1/4);
            %%%%% Update W %%%%%
            for i=1:I
                for j=1:J
                    H(:,j) = squeeze(X(i,j,:)) / L(i,j,n);
                end
                w = squeeze(W(n,:,i)); %w_in 転置
                q = ( w * H )';
                keisu = sqrt( beta ) / ( 2*sqrt(J*sum( abs(q) .^ beta ) ) );
                F = q(1) / R(i,1,n)^2 * squeeze( X(i,1,:) ) * squeeze(  X(i,1,:) )';
                for j=2:J
                    F = F + q(j) / R(i,j,n)^2 * squeeze( X(i,j,:) ) * squeeze(  X(i,j,:) )';
                end
                G = keisu * ( norm(q)^2 * (H * H') + F - (H*q)*(H*q)' );
                w_mm = ( squeeze( W(:,:,i) ) * G ) \ E(:,n);
                w = w'; %wをたてベクトルに
                w = 2 * ( w_mm' * G * w ) / ( w_mm' * G * w_mm ) * w_mm - w;
                w = w * ( 2*J / ( beta * sum( ( (squeeze( X(i,:,:) ) * w  ./ squeeze(R(i,:,n))' ) ) )))^(1/beta);
                W(n,:,i) = w';
            end
        end
        
        if drawConv
            cost(it+1,1) = costFunction_local( X, R, W, I, J, N, beta );
        end
    end
    fprintf(' ILRMA1 done.\n');
    
%%%%%%%%%%%%%%%%%%%%%%%%%%% ILRMA2 %%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif (type==2) % Algorithm for ILRMA2
    A = zeros(N,K);
    B = zeros(I,K);
    C = zeros(K,J);
    UN1 = ones(N,1);
    U1J = ones(1,J);
    UNN = ones(N,N);
    UI1 = ones(I,1);
    UJ1 = ones(J,1);
    Z  = Z./(UNN*Z); % ensuring sum_n z_{nk}=1
    for n=1:N
        R(:,:,n) = ((UI1)*Z(n,:).*T)*V; % source model
    end
    if drawConv
        cost(1,1) = costFunction_local( P, R, W, I, J );
    end
    
    % Iterative update
    fprintf('Iteration:    ');
    for it=1:It
        fprintf('\b\b\b\b%4d', it);
        %%%%% Update Z %%%%%
        for n=1:N
            Pn = P(:,:,n); % I x J
            Rn = R(:,:,n); % I x J
            A(n,:) = (( ((T.'*(Pn.*Rn.^(-2))).*V)*UJ1 )./( ((T.'*(Rn.^(-1))).*V)*UJ1 )).';
        end
        Z = Z.*sqrt(A);
        Z = Z./(UNN*Z); % ensuring sum_n z_{nk}=1
        Z = max(Z,eps);
        for n=1:N
            R(:,:,n) = ((UI1)*Z(n,:).*T)*V; % source model
        end
        %%%%% Update T %%%%%
        for i=1:I
            Pi = squeeze(P(i,:,:)); % J x N
            Ri = squeeze(R(i,:,:)); % J x N
            B(i,:) = (( ((V*(Pi.*Ri.^(-2))).*(Z.'))*UN1 )./( ((V*(Ri.^(-1))).*(Z.'))*UN1 )).';
        end
        T = T.*sqrt(B);
        T = max(T,eps);
        for n=1:N
            R(:,:,n) = ((UI1)*Z(n,:).*T)*V; % source model
        end
        %%%%% Update V %%%%%
        for j=1:J
            Pj = squeeze(P(:,j,:)); % I x N
            Rj = squeeze(R(:,j,:)); % I x N
            C(:,j) = ( ((T.'*(Pj.*Rj.^(-2))).*(Z.'))*UN1 )./( ((T.'*(Rj.^(-1))).*(Z.'))*UN1 );
        end
        V = V.*sqrt(C);
        V = max(V,eps);
        for n=1:N
            R(:,:,n) = ((UI1)*Z(n,:).*T)*V; % source model
        end
        %%%%% Update W %%%%%
        for n=1:N
            for i=1:I
                D = ((Xp(:,:,i).*(UN1*(U1J./R(i,:,n))))*Xp(:,:,i)')/J; % M x M
                w = (W(:,:,i)*D)\E(:,n); % M x 1
                w = w/sqrt((w')*D*w); % M x 1
                W(n,:,i) = w';
                S(i,:,n) = (w')*Xp(:,:,i);
            end
        end
        P = max(abs(S).^2,eps);
        %%%%% Normalization %%%%%
        if normalize
            %%%%%%%%%%%%%%%%%%%%%%%%%%% !!!NOTE!!! %%%%%%%%%%%%%%%%%%%%%%%%
            % This normalization increases the computational stability,   %
            % but the monotonic decrease of the cost function may be lost %
            % because of the numerical errors in this normalization.      %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            lambda = sqrt(sum(sum(P,1),2)/(I*J)); % 1 x 1 x N
            lambdaN = squeeze(lambda); % N x 1
            W = W./repmat(lambdaN,[1,M,I]); % N x M x I
            lambdaIJ = repmat(lambda,[I,J,1]).^2; % I x J x N
            P = P./lambdaIJ; % I x J x N
            R = R./lambdaIJ; % I x J x N
            Zlambda = Z./repmat(lambdaN,[1,K]).^2; % N x K
            ZlambdaSum = sum(Zlambda,1); % 1 x K
            T = T.*repmat(ZlambdaSum,[I,1]); % I x K
            Z = Zlambda./repmat(ZlambdaSum,[N,1]); % N x K
        end
        if drawConv
            cost(it+1,1) = costFunction_local( P, R, W, I, J );
        end
    end
    fprintf(' ILRMA2 done.\n');
end

if drawConv
    figure;
    plot( (0:it), abs(cost) );
    set(gca,'FontName','Times','FontSize',16);
    xlabel('Iteration','FontName','Arial','FontSize',16);
    ylabel('Value of cost function','FontName','Arial','FontSize',16);
end
end

%% Local function
function [ cost ] = costFunction_local( X, R, W, I, J, N, beta )
cost = 0;
for i=1:I
    x = abs(det(W(:,:,i)));
    if x == 0
        x = eps;
    end
    for j=1:J
        for n=1:N
            cost = cost + squeeze(W(n,:,i))*squeeze(X(i,j,:)) / R(i,j,n)^beta ...
                + 2 * log( R(i,j,n ) );
        end
    end
    cost = cost + log( x );
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EOF %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%