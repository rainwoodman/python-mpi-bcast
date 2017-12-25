cat >process.awk <<EOF
NR == 31 {printf("%g ", \$3);}
NR == 32 {printf("%g ", \$3);}
NR == 33 {printf("%g ", \$3);}
NR == 35 {
       split(\$2, a, "m"); 
       printf("%g ", a[1] * 60 + a[2]);
}
NR == 41 {
      split(\$2, a, "m"); 
      printf("%g \n", a[1] * 60 + a[2]);
}
EOF
echo "# N bcast tar chmod bcasttot launch"
for i in 1 2 4 8 16 32 64 128 256 512 1024 2048 4096 5310; do
    echo -n "$i "
    awk -f process.awk bench-$i.out
done
