from matplotlib.backends.backend_agg import FigureCanvasAgg
from matplotlib.figure import Figure
import numpy

nodes, bcast, tar, chmod, bcasttot, launch = numpy.loadtxt('./collect.txt', unpack=True)

f = Figure(figsize=(4, 4))
ax = f.add_subplot(111)

ax.plot(nodes * 32, launch, 's ', color='r', mec='none', label='import scipy')
ax.plot(nodes * 32, bcasttot, ls='none', marker=(8, 2, 0), color='m', label='bcast')
ax.plot(nodes * 32, bcast, 'x ', color='g', mew=1, label='bcast/MPI_Bcast')
ax.plot(nodes * 32, tar,   '+ ', color='b', mew=1, label='bcast/tar xzvf')
ax.plot(nodes * 32, launch + bcasttot, 'D ', color='k', label='total')

ax.set_xlabel('Number of Ranks')
ax.set_ylabel('Wall time [sec]')
ax.set_xscale('log')
ax.set_yscale('log')
ax.set_ylim(3e-1, 2e3)
#ax.grid()
ax.legend(loc='upper left', frameon=False, ncol=1, fontsize='small')
canvas = FigureCanvasAgg(f)
f.tight_layout()
f.savefig('cray-xc30-startup-time.png', dpi=72)
f.savefig('cray-xc30-startup-time-hires.png', dpi=200)
f.savefig('cray-xc30-startup-time-hires.pdf', dpi=200)
