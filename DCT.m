clc;
clear all;
close all;

% Select image
[filename, pathname] = uigetfile('*.jpg', 'Select an image?');
if ~ischar(filename); return; end      %user cancelled
filepath = fullfile(pathname, filename);
I = imread(filepath);
% figure, imshow(I);

fprintf('Resim import edildi.\n');

% RGB to YCbCr
YCbCr = rgb2ycbcr(I);

% Y component of Image
Y = YCbCr(:,:, 1);
% figure, imshow(Y);

[h, w] = size(Y);
r = h/8;
c = w/8;

s = 1;

% Take Q as an input
prompt = {'Enter the Q Value:'};
name = 'Q Value';
answer=inputdlg(prompt,name);
Q = str2double(answer{1});

fprintf('Q value received: %d \n',Q);

% Base Quantization Matrix and Quantization Matrix Calculation
Tb = [16 11 10 16 24 40 51 61;
      12 12 14 19 26 58 60 55;
      14 13 16 24 40 57 69 56;
      14 17 22 29 51 87 80 62;
      18 22 37 56 68 109 103 77;
      24 35 55 64 81 104 113 92;
      49 64 78 87 103 121 120 101;
      72 92 95 98 112 100 103 99];

%// Determine S
if (Q < 50)
    S = 5000/Q;
else
    S = 200 - 2*Q;
end

Ts = floor((S*Tb + 50) / 100);
Ts(Ts == 0) = 1; % // Prevent divide by 0 error

% % % % % % % %
% COMPRESSION %
% % % % % % % %

for i=1:r
    e = 1;
    for j=1:c
        block = Y(s:s+7,e:e+7);
        cent = double(block) - 128;
        for m=1:8
            for n=1:8
                if m == 1
                    u = 1/sqrt(8);
                else
                    u = sqrt(2/8);
                end
                if n == 1
                    v = 1/sqrt(8);
                else
                    v = sqrt(2/8);
                end
                comp = 0;
                for x=1:8
                    for y=1:8
                        comp = comp + cent(x, y)*(cos((((2*(x-1))+1)*(m-1)*pi)/16))*(cos((((2*(y-1))+1)*(n-1)*pi)/16));
                    end
                end
                    F(m, n) = v*u*comp;
            end
        end
        for x=1:8
            for y=1:8
                cq(x, y) = round(F(x, y)/Ts(x, y));
            end
        end
        Q(s:s+7,e:e+7) = cq;
        e = e + 8;
    end
    s = s + 8;
end

fprintf('Comprassion has been completed. \n');

% figure
% h = imagesc(Q);
% impixelregion(h);

% % % % % % % % %      
% DECOMPRESSION %
% % % % % % % % %

s = 1;
for i=1:r
    e = 1;
    for j=1:c
        cq = Q(s:s+7,e:e+7);
        for x=1:8
            for y=1:8
                DQ(x, y) = Ts(x, y)*cq(x, y); 
            end
        end
        for x = 1:8
            for y = 1:8
                comp = 0;
                for m = 1:8
                    for n = 1:8
                        if m == 1
                            u = 1/sqrt(2);
                        else
                            u = 1;
                        end
                        if n == 1
                            v = 1/sqrt(2);
                        else
                            v = 1;
                        end
            
                        comp = comp + u*v*DQ(m, n)*(cos((((2*(x-1))+1)*(m-1)*pi)/16))*(cos((((2*(y-1))+1)*(n-1)*pi)/16));
                    end
                end
                bf(x, y) =  round((1/4) *comp + 128);           
            end
        end
        Org(s:s+7,e:e+7) = bf;
        e = e + 8;
    end
    s = s + 8;
end

fprintf('Decompression has been completed. \n');

YCbCr(:,:,1) = uint8(Org);
O = ycbcr2rgb(YCbCr);
imwrite(O, 'outputRGB.jpg');

fprintf('Output image has been saved. \n');

% MSE calculation
msError = immse(O,I);
psnr = psnr(O,I);

message = sprintf('The mean square error is %.2f',msError);
message2 = sprintf('The PSNR value is %.2f',psnr);
msgbox(message);
msgbox(message2);

figure
imshow('outputRGB.jpg');

return;