%% clear workspace
clc;clear all;
%% load_data
 img1 = LoadRF('data/RF_B_00000.pgm');
img2 = LoadRF('data/RF_B_00001.pgm');
img3 = LoadRF('data/RF_B_00002.pgm');
img4 = LoadRF('data/RF_B_00003.pgm');
img5 = LoadRF('data/RF_B_00004.pgm');
img6 = LoadRF('data/RF_B_00005.pgm');
f=(img1+img2+img3+img4+img5+img6)/6;
% f1=f';
img=f;
% figure,imagesc(abs(f)),colormap('gray');colorbar;
% %[num_lines,mgraph]=size(f);

%% ��������
[lines,points]=size(img);
depth=3;%���
r=0.4; %Ƶ���������
alpha=0.2; %˥��ϵ��
width=3.81;%���
c=1.54*10^5;%�ٶ�
d=(0:points-1).*depth/points;%ÿ�������
fs=points*c/2/depth; %����Ƶ��41.53MHz
fc=10000000;%̽ͷ����Ƶ��
depth_pix=512;
width_pix=round(depth_pix/depth*width);
gap=fs/1618;
time=(0:points-1)/fs;
freq=0:gap:fs-fs/1618; %ʵ��ÿ����Ƶ��
for line_no=1:lines
    a_line=img(line_no,:);
    number=66;
    %% ȥ��ֱ��
    %��ͨ�˲������
    wp=pi/2;ws=pi/7;
    highpass=wp-ws;
    N0=ceil(6.8*pi/highpass);
    N_highpass=N0+mod(N0+1,2);
    wc=(wp+ws)/2/pi; %����Ƶ��
    highpass_filt=fir1(N_highpass-1,wc,'high',hanning(N_highpass)); %FIR butterworth highpass filter
    a_line_filtered=fftfilt(highpass_filt,a_line);
    figure(1); %ԭʼ����ͨ�˲�
    if(line_no==number) %��һ����һ��
        subplot(221);
        plot(time,a_line);title('ԭʼ��Ƶʱ��');
        subplot(222);plot(time,a_line_filtered);title('�˲���ʱ��');
        subplot 223;plot(freq,abs(fft(a_line)));title('ԭʼ��ƵƵ��');
        subplot 224;plot(freq,abs(fft(a_line_filtered)));title('��ͨ�˲���Ƶ��');
    end
    
    %% �������
    f_shift=0.11513*(fc*r)^2/(2*log(2))*alpha.*d;
    f_1=fc-f_shift; %��̬Ƶ��
    Q=a_line_filtered.*cos(2*pi*f_1.*time);
    I=a_line_filtered.*sin(2*pi*f_1.*time);
    if(line_no==number) 
        figure(2); %�������
        subplot(221);
        plot(Q);%hold on;plot(a_line_filtered);
        title('������Q');
        subplot(222);
        plot(I);%hold on;plot(a_line_filtered);
        title('������I');
        subplot(223);
        plot(abs(fft(Q)));%hold on;plot(freq,abs(fft(a_line_filtered)));
        title('������Q in Ƶ��');
        subplot(224);
        plot(abs(fft(I)));%hold on;plot(freq,abs(fft(a_line_filtered)));
        title('������I in Ƶ��');
    end
    %% ��˹��ͨ�˲�
    lp_width=0.03;
    dz=depth/points;
    numz=2*round(2*lp_width/dz)+1;
    z2=dz*(-numz/2:(numz/2+1))';
    sigma=lp_width/4; %��׼��
    LPF=((2*pi)^.5*sigma)^-1*exp(-.5*(z2/sigma).^2);
    Q_filtered=fftfilt(LPF,Q);
    I_filtered=fftfilt(LPF,I);
    lp_result=sqrt(Q_filtered.^2+I_filtered.^2);
    %��ͼ����
    if(line_no==number)
        figure(6);
        subplot 221
        plot(time,a_line_filtered);title('��ͨ�˲�ǰ��ʱ��');
        subplot 222
        plot(freq,abs(fft(a_line_filtered)));title('��ͨ�˲�ǰ��Ƶ��');
        subplot 223
        plot(time,lp_result);title('��ͨ�˲����ʱ��');
        subplot 224
        plot(freq,abs(fft(lp_result)));title('��ͨ�˲����Ƶ��');
    end
    
    %% ʱ�����油��
    beta=log(10)*alpha*fc/20;
    TGC_Matrix=1-exp(-beta.*d);
    I_TGC=I_filtered.*TGC_Matrix;
    Q_TGC=Q_filtered.*TGC_Matrix;
    envelop_IQ=sqrt(I_TGC.^2+Q_TGC.^2); %����
    if(line_no==number)
        figure(3); %�²���
        subplot 221
        plot(abs(envelop_IQ));title('�²���ǰʱ����');
        subplot 222;
        plot(abs(fft(envelop_IQ)));title('�²���ǰƵ��');
    end
    %% �²���
    per_pix=fix(points/512);
    downsp=zeros(1,512);
    for i=1:512
        downsp(1,i)=envelop_IQ(1,3*(i-1)+1);
    end
    if(line_no==number)
        subplot 223;
        plot(abs(downsp));title('�²�����ʱ����');
        subplot 224;
        plot(abs(fft(downsp)));title('�²�����Ƶ��');
    end
    one_frame(line_no,:)=downsp;
end
% % %% �����任
% D=100;G=0;
% % for nlog=1:168
% %     for i=1:512
% %         q=D*log10(abs(one_frame(nlog,i))+1)+G;
% %         if q>255
% %             q=255;
% %         end
% %         logdata(nlog,i)=q;
% %     end
% % end
%% �����任new
D=60;G=0;
logdata=D*log10(one_frame+1)+G;
logdata=logdata';
figure;
imshow(one_frame',[]);
title('�ؽ�ͼ��');
figure;
imshow(logdata,[]);
title('�����任���ͼ��');
%% ��ֵ��ʾ
for i=1:size(logdata,1)
    for j=1:size(logdata,2)-1
        Interp_Out(i,2*j-1)=logdata(i,j);
        Interp_Out(i,2*j)=logdata(i,j)+0.5*(logdata(i,j+1)-logdata(i,j));
    end
end

figure 
b=(Interp_Out-min(Interp_Out(:)))./(max(Interp_Out(:))-min(Interp_Out(:)))*255;%%aΪdouble��
b=b-50;
imshow(uint8(b));   
title('��ֵ���ͼ��')