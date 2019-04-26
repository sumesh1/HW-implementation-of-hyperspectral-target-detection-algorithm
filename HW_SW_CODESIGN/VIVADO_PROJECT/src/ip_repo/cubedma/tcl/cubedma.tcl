proc init {} {
    ps7_init
    ps7_post_config
}

proc fill_memory {n bpc} {
    set mask [expr ~(1 << $bpc)]
    set temp 0
    set num_bits 0
    set offset 0
    set addr 0x00100000
    set num_comps [expr int(ceil(32.0 / $bpc))]
    for {set i 0} {$i < $n} {incr i} {
        set temp_word 0
        for {set j 0} {$j < $num_comps} {incr j} {
            set temp_word [expr $temp_word | ((($i * $num_comps + $j) & $mask) << ($bpc * $j))]
            set num_bits [expr $num_bits + $bpc]
        }
        set temp [expr $temp | ($temp_word << $offset)]
        puts [format 0x%x $temp]
        while {$num_bits >= 32} {
            mwr $addr [expr $temp & 0xFFFFFFFF]
            set temp [expr $temp >> 32]
            set num_bits [expr $num_bits - 32]
            set offset $num_bits
            set addr [expr $addr + 4]
        }
    }
}

proc mm2s_transfer {regbase mode_block mode_plane base offset width height depth block_width block_height last_block_row_length line_skip plane_transfers} {
    mwr -force [expr $regbase + 0x00] 0
    mwr -force [expr $regbase + 0x08] $base
    mwr -force [expr $regbase + 0x0C] [expr (($depth & 0xFF) << 24) | (($height & 0xFFF) << 12) | ($width & 0xFFF)]
    mwr -force [expr $regbase + 0x10] [expr (($last_block_row_length & 0xFFFFF) << 12) | (($block_height & 0xF) << 4) | ($block_width & 0xF)]
    mwr -force [expr $regbase + 0x14] $line_skip
    mwr -force [expr $regbase + 0x00] [expr (($plane_transfers & 0xFF) << 8) | (($mode_plane & 1) << 3) | (($mode_block & 1) << 2) | 1]
}

proc mm2s_simple_transfer {regbase base length {offset 0}} {
    mm2s_transfer $regbase 0 0 $base $offset 1 1 1 0 0 0 $length 1
}

proc s2mm_transfer {regbase base} {
    mwr -force [expr $regbase + 0x20] 0
    mwr -force [expr $regbase + 0x28] $base
    mwr -force [expr $regbase + 0x20] 1
}

