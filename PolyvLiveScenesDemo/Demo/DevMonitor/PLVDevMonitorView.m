//
//  PLVDevMonitorView.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/5/29.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVDevMonitorView.h"
// 性能监控所需头文件
#import <mach/mach.h>
#import <mach/task.h>
#import <mach/thread_act.h>
#import <mach/vm_map.h>

@interface PLVDevMonitorView ()

// 性能监控相关
@property (nonatomic, strong) NSTimer *performanceTimer; // 性能监控定时器
@property (nonatomic, strong) UILabel *performanceLabel; // 性能信息显示Label
@property (nonatomic, assign) BOOL performanceMonitorEnabled; // 是否启用性能监控

@end

@implementation PLVDevMonitorView

+ (void)showInWindown{
    PLVDevMonitorView *devMonitorView = [[PLVDevMonitorView alloc] initWithFrame:CGRectMake(0, 150, 200, 80)];

    // 获取keyWindow
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    [keyWindow addSubview:devMonitorView];
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]){
        [self setupCPUAndMemoryUsage];
        
        [self startPerformanceMonitoring];
    }
    
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    [self layoutPerformanceLabel];
}

- (void)setupCPUAndMemoryUsage {
    // 统计显示CPU 内存占用

    // 创建性能信息显示标签
    if (!self.performanceLabel) {
        self.performanceLabel = [[UILabel alloc] init];
        self.performanceLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        self.performanceLabel.textColor = [UIColor whiteColor];
        self.performanceLabel.font = [UIFont systemFontOfSize:12];
        self.performanceLabel.textAlignment = NSTextAlignmentLeft;
        self.performanceLabel.numberOfLines = 0;
        self.performanceLabel.layer.cornerRadius = 6;
        self.performanceLabel.layer.masksToBounds = YES;
        
        // 添加到主视图
        [self addSubview:self.performanceLabel];
    }
     
}

- (void)startPerformanceMonitoring {
    if (self.performanceTimer) {
        [self.performanceTimer invalidate];
        self.performanceTimer = nil;
    }

    // 每2秒更新一次性能信息
    self.performanceTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                             target:self
                                                           selector:@selector(updatePerformanceInfo)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)stopPerformanceMonitoring {
    if (self.performanceTimer) {
        [self.performanceTimer invalidate];
        self.performanceTimer = nil;
    }
}

- (void)updatePerformanceInfo {
//    if (!self.performanceMonitorEnabled || self.performanceLabel.hidden) {
//        return;
//    }

    // 获取CPU使用率
    float cpuUsage = [self getCPUUsage];

    // 获取内存使用情况
    NSUInteger memoryUsage = [self getMemoryUsage]; // MB
    NSUInteger totalMemory = [self getTotalMemory]; // MB
    float memoryPercentage = totalMemory > 0 ? (float)memoryUsage / totalMemory * 100.0 : 0.0;

    // 获取当前时间
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [formatter stringFromDate:[NSDate date]];

    // 格式化显示信息
    NSString *performanceText = [NSString stringWithFormat:@"📊 性能监控 [%@]\n🔥 CPU: %.1f%%\n💾 内存: %lu MB (%.1f%%)\n📱 总内存: %lu MB",
                                timeString, cpuUsage, (unsigned long)memoryUsage, memoryPercentage, (unsigned long)totalMemory];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.performanceLabel.text = performanceText;
        [self layoutPerformanceLabel];
    });
}

- (void)layoutPerformanceLabel {
    self.performanceLabel.frame = self.bounds;
    // 获取keyWindow
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    [keyWindow bringSubviewToFront:self];
}

#pragma mark - CPU和内存获取方法

- (float)getCPUUsage {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;

    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return 0.0;
    }

    thread_array_t thread_list;
    mach_msg_type_number_t thread_count;

    thread_info_data_t thinfo;
    mach_msg_type_number_t thread_info_count;

    thread_basic_info_t basic_info_th;

    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return 0.0;
    }

    float total_cpu = 0.0;

    for (int i = 0; i < thread_count; i++) {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[i], THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            continue;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            total_cpu += basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
    }

    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));

    return total_cpu;
}

- (NSUInteger)getMemoryUsage {
    struct mach_task_basic_info info;
    mach_msg_type_number_t size = MACH_TASK_BASIC_INFO_COUNT;
    kern_return_t kerr = task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &size);

    if (kerr == KERN_SUCCESS) {
        return info.resident_size / 1024 / 1024; // 转换为MB
    }
    return 0;
}

- (NSUInteger)getTotalMemory {
    return [NSProcessInfo processInfo].physicalMemory / 1024 / 1024; // 转换为MB
}


@end
