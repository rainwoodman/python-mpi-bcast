from matplotlib.backends.backend_agg import FigureCanvasAgg
from matplotlib.figure import Figure
import numpy

data2 = numpy.loadtxt('bench-log2.txt').reshape(-1, 6).T
data3 = numpy.loadtxt('bench-log3.txt').reshape(-1, 6).T
print data2.shape, data3.shape
f = Figure(figsize=(5, 4))
ax = f.add_subplot(111)
l = []
for i in range(5):
    ll,  = ax.plot(data2[0]- data2[0][0] + 1, data2[i+1])
    ax.plot(data3[0] - data3[0][0] + 1, data3[i+1], color=ll.get_color(), ls='--')
    l.append(ll)
ax.legend(
    l,
    ['Bare Python', 'import numpy', 'import scipy', 'import numba', 'import matplotlib'], 
    fontsize='small', frameon=False, loc='upper left')

ax.set_ylabel("File-System Operations")
ax.set_xlabel("Length of PYTHONPATH")
canvas = FigureCanvasAgg(f)
f.tight_layout()
f.savefig('python-file-ops.png', dpi=200)
f.savefig('python-file-ops.pdf', dpi=200)
