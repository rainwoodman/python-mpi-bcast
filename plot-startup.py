from matplotlib.backends.backend_agg import FigureCanvasAgg
from matplotlib.figure import Figure
import numpy

mppwidth, time = numpy.loadtxt('./startup-time.txt', unpack=True)
f = Figure(figsize=(4, 3))
ax = f.add_subplot(111)
ax.plot(mppwidth[1:], time[1:], 'x ', markersize=16, markeredgewidth=3)
ax.axhline(time[0], lw=3, ls=':', label='mppwidth=48')
ax.set_xlabel('mppwidth')
ax.set_ylabel('wall time [sec]')
ax.set_title('import scipy')
#ax.set_xlim(, 40000)
#ax.set_ylim(1, 100)
ax.set_xscale('log')
ax.set_yscale('log')
ax.grid()
ax.legend(loc='upper left', frameon=False)
canvas = FigureCanvasAgg(f)
f.tight_layout()
f.savefig('startup-time.png', dpi=200)
