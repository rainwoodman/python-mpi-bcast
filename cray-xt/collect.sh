cat >process.awk <<EOF
NR == 49 {printf("%g ", \$3);}
NR == 50 {printf("%g ", \$3);}
NR == 51 {printf("%g ", \$3);}
NR == 54 {
       split(\$2, a, "m"); 
       printf("%g ", a[1] * 60 + a[2]);
}
NR == 61 {
      split(\$2, a, "m"); 
      printf("%g \n", a[1] * 60 + a[2]);
}
EOF
echo "# N bcast tar bcasttot0 bcasttot launch"
for i in 1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192; do
    echo -n "$i "
    awk -f process.awk bench-$i.out
done
