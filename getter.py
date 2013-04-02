import gzip
import re
import os
arr =['chr1:43148402..43149073,+']
arr_2 = []
for a in arr:
  chromos,b=a.split(':')
  start,d=b.split('..')
  end,sign=d.split(',')
  start,end=int(start),int(end)
  arr_2.append((chromos,sign,start,end))
dirs =  ['/home/storage/fantom_update21/human.cell_line.hCAGE/', 
#  '/home/storage/fantom_update21/human.cell_line.LQhCAGE/',
  '/home/storage/fantom_update21/human.fractionation.hCAGE/',
  '/home/storage/fantom_update21/human.primary_cell.hCAGE/',
#  '/home/storage/fantom_update21/human.primary_cell.LQhCAGE/',
  '/home/storage/fantom_update21/human.qualitycontrol.hCAGE/',
  '/home/storage/fantom_update21/human.timecourse.hCAGE/',
#  '/home/storage/fantom_update21/human.timecourse.LQhCAGE/',
  '/home/storage/fantom_update21/human.tissue.hCAGE/']
#dirs = ['./']

for dir in dirs:
  for fi in os.listdir(dir):
    if fi[-2:] <> ('gz'):
      continue
    
    tissue_type = dir.split('/')[-2]
    if tissue_type not in os.listdir('.'):
      os.mkdir(tissue_type)
    print(dir+'--> '+tissue_type+'/'+fi[0:-2]+'txt')
    f1 = open(tissue_type + '/' + fi[0:-2]+'txt', 'w')
    
    f=gzip.open(dir+fi,mode='r')
    for s in f:
      chromos_check,start_check,end_check,line_check,height_check,sign_check= s.split()
      chromos_check=chromos_check.decode()
      height_check=height_check.decode()
      start_check=int(start_check)
      end_check=int(end_check)
      for peak in arr_2:
        #print(a)
        chromos,sign,start,end = peak 
          
        if chromos==chromos_check and start_check>=start and end_check<=end and sign_check==sign:
          f1.write('\t'.join([chromos,sign,str(start_check),str(height_check)])+'\n')
    f.close()
    f1.close()
print('Finished')


