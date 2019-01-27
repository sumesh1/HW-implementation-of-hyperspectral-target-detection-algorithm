function normA = normalize(A)
% Normalizes 2 or 3 dimension matrix to values between 0 and 1

normA = A;

dims = size(A);
dim3=1;

if length(dims) > 2
    dim3 = dims(3);
end

for k=1:dim3
    tmpMax = max(max(A(:,:,k)));
    tmpMin = min(min(A(:,:,k)));
    
    normA(:,:,k) = (A(:,:,k) - tmpMin)/(tmpMax - tmpMin);
end