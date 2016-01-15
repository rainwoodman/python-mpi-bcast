from matplotlib.backends.backend_agg import FigureCanvasAgg
from matplotlib.figure import Figure
import numpy

nodes, bcast, tar, chmod, bcasttot, launch = numpy.loadtxt('./collect.txt', unpack=True)

f = Figure(figsize=(5, 5))
ax = f.add_subplot(111)

ax.plot(nodes * 24, launch, 's ', color='k', label='import scipy')
ax.plot(nodes * 24, bcasttot, 'o ', color='k', label='bcast')
ax.plot(nodes * 24, bcast, 'x ', color='k', mew=2, label='bcast/MPI_Bcast')
ax.plot(nodes * 24, tar,   '+ ', color='k', mew=2, label='bcast/tar xzvf')
ax.plot(nodes * 24, launch + bcasttot, 'd ', color='k', label='total')

ax.set_xlabel('Number of Ranks')
ax.set_ylabel('Wall time [sec]')
ax.set_xscale('log')
ax.set_yscale('log')
ax.grid()
ax.legend(loc='lower right', frameon=True, ncol=2, fontsize='small')
canvas = FigureCanvasAgg(f)
f.tight_layout()
f.savefig('cray-xc30-startup-time.png', dpi=72)
f.savefig('cray-xc30-startup-time-highres.png', dpi=200)
