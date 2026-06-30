# Meter

## Basic meter

```tcl
ttkbootstrap::Meter .m \
    -metersize  150 \
    -amountused 75 \
    -subtext    "Usage" \
    -bootstyle  info
pack .m
```

## Interactive meter

Users can click/drag to change the value:

```tcl
ttkbootstrap::Meter .m \
    -metersize   150 \
    -amountused  45 \
    -amounttotal 100 \
    -subtext     "Score" \
    -bootstyle   success \
    -interactive 1
pack .m
```

## Semi-circle meter

```tcl
ttkbootstrap::Meter .m \
    -metertype  semi \
    -metersize  200 \
    -amountused 60 \
    -subtext    "Progress" \
    -bootstyle  warning
pack .m
```

