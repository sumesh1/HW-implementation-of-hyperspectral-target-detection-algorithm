A = gt';
cmap = [1 1 1; 0 0 0; 0 0 1; 0 1 0; 0 1 1; 1 0 0; 1 0 1; 1 1 0; 0.5 0.5 0.5; 
    0 0 0.5; 0 0.5 0 ; 0 0.5 0.5; 0.5 0 0; 0.5 0 0.5; 0.5 0.5 0; 0.4 0.2 0.82; 0.1 0.5 0.7];


figure(1)
imagesc(A);
colormap(cmap);

minA = min(min(A));
maxA = max(max(A));

legends = ['Background',em];

%for hopavaagen
%legends = [em];


hold on;
for K = minA : maxA; hidden_h(K-minA+1) = surf(uint8([K K;K K]), 'edgecolor', 'none'); end
hold off
 

display('here')
uistack(hidden_h, 'bottom');

legend(hidden_h, legends(1:maxA+1),'interpreter','none','location','bestoutside' )

%for hopavaagen
%legend(hidden_h, legends(1:maxA),'interpreter','none','location','bestoutside' )

print(gcf,'foo.png','-dpng','-r300');  