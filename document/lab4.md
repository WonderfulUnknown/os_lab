[TOC]
# 练习1
## mmio_map_region
该函数用于在内存中预留一部分空间给IO来访问LAPIC（局部高级可编程中断控制器）单元
根据注释可知此处页面的权限位应该另外加上PTE_PCD|PTE_PWT，使得cache不缓存这部分的内容，采用直接写回的策略。