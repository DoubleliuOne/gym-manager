import router from '@ohos.router';
import { get, post, put } from '../utils/HttpUtil';
import { BookingRequest, CancelBookingRequest, CheckinRequest } from '../utils/HttpUtil';

/* ========== 类型定义 ========== */

interface ScheduleItem {
  id: number;
  courseId: number;
  coachId: number;
  classDate: string;
  startTime: string;
  endTime: string;
  actualCapacity: number;
  bookedCount: number;
  status: number;
}

interface CourseItem {
  id: number;
  name: string;
  description: string;
  maxCapacity: number;
  durationMinutes: number;
  status: number;
}

interface CoachItem {
  id: number;
  name: string;
  phone: string;
  specialty: string;
  status: number;
}

interface CardItem {
  id: number;
  memberId: number;
  templateId: number;
  startDate: string;
  endDate: string;
  remainingCount: number;
  status: number;
}

interface BookingItem {
  id: number;
  memberId: number;
  scheduleId: number;
  status: number;
  bookedAt: string;
  checkedInAt: string | null;
}

interface MemberInfo {
  id: number;
  name: string;
  phone: string;
  gender: number;
  birthday: string | null;
  avatarUrl: string | null;
  status: number;
}

interface RenewalRecord {
  id: number;
  memberId: number;
  cardId: number;
  templateId: number;
  amount: number;
  paymentMethod: number;
  remark: string;
  renewalDate: string;
}

/* ========== 工具函数 ========== */

function getTimeLabel(time: string): string {
  return time.substring(0, 5);
}

function getDateLabel(date: string): string {
  return date.replace(/-/g, '/');
}

function getBookingStatusText(status: number): string {
  switch (status) {
    case 0: return '已预约';
    case 1: return '已签到';
    case 2: return '已取消';
    default: return '未知';
  }
}

function getBookingStatusColor(status: number): string {
  switch (status) {
    case 0: return '#e6a817';
    case 1: return '#2ecc71';
    case 2: return '#999999';
    default: return '#666666';
  }
}

function getBookingStatusBg(status: number): string {
  switch (status) {
    case 0: return '#fff8e6';
    case 1: return '#e8f8ef';
    case 2: return '#f5f5f5';
    default: return '#f5f5f5';
  }
}

/* ========== 主页面 ========== */

@Entry
@Component
struct Index {
  /* --- 课程列表相关状态 --- */
  @State scheduleList: ScheduleItem[] = [];
  @State courseMap: Record<number, string> = {};
  @State coachMap: Record<number, string> = {};
  @State loadingCourses: boolean = true;

  /* --- 我的相关状态 --- */
  @State member: MemberInfo | null = null;
  @State cardList: CardItem[] = [];
  @State bookingList: BookingItem[] = [];
  @State scheduleDetailMap: Record<number, string> = {};
  @State renewalList: RenewalRecord[] = [];
  @State loadingMy: boolean = true;

  /* --- UI 状态 --- */
  @State currentTab: number = 0;

  aboutToAppear(): void {
    this.checkAuth();
    this.loadCoursesTab();
    this.loadMyTab();
  }

  checkAuth(): void {
    const token = AppStorage.get<string>('token');
    if (!token) {
      try {
        router.replaceUrl({ url: 'pages/Login' });
      } catch (_) {}
      return;
    }
    const memberData = AppStorage.get<object>('member');
    if (memberData) {
      this.member = memberData as MemberInfo;
    }
  }

  /* ========== 数据加载 ========== */

  async loadCoursesTab(): Promise<void> {
    this.loadingCourses = true;
    try {
      const schedules = await get<ScheduleItem[]>('/schedules');
      const courses = await get<CourseItem[]>('/courses');
      const coaches = await get<CoachItem[]>('/coaches');
      this.scheduleList = schedules;

      let cm: Record<number, string> = {};
      for (let i = 0; i < courses.length; i++) {
        cm[courses[i].id] = courses[i].name;
      }
      this.courseMap = cm;

      let com: Record<number, string> = {};
      for (let i = 0; i < coaches.length; i++) {
        com[coaches[i].id] = coaches[i].name;
      }
      this.coachMap = com;
    } catch (err) {
      const msg = (err as Error).message || '加载课程列表失败';
      AlertDialog.show({
        title: '提示',
        message: msg,
        confirm: { value: '确定', action: () => {} }
      });
    }
    this.loadingCourses = false;
  }

  async loadMyTab(): Promise<void> {
    this.loadingMy = true;
    try {
      if (!this.member) {
        this.loadingMy = false;
        return;
      }
      const mid = this.member.id;

      const cards = await get<CardItem[]>('/members/' + mid + '/cards');
      const bookings = await get<BookingItem[]>('/bookings/member/' + mid);
      const renewals = await get<RenewalRecord[]>('/statistics/member-renewals?memberId=' + mid);

      this.cardList = cards;
      this.bookingList = bookings;
      this.renewalList = renewals;

      let sdm: Record<number, string> = {};
      for (let i = 0; i < bookings.length; i++) {
        try {
          const sd = await get<ScheduleItem>('/schedules/' + bookings[i].scheduleId);
          const courseName = this.courseMap[sd.courseId] || ('课程#' + sd.courseId);
          sdm[bookings[i].scheduleId] = courseName + ' ' + getDateLabel(sd.classDate) + ' ' + getTimeLabel(sd.startTime);
        } catch (_) {
          sdm[bookings[i].scheduleId] = '排课#' + bookings[i].scheduleId;
        }
      }
      this.scheduleDetailMap = sdm;
    } catch (err) {
      const msg = (err as Error).message || '加载我的信息失败';
      AlertDialog.show({
        title: '提示',
        message: msg,
        confirm: { value: '确定', action: () => {} }
      });
    }
    this.loadingMy = false;
  }

  async handleBooking(scheduleId: number): Promise<void> {
    if (!this.member) {
      AlertDialog.show({
        title: '提示',
        message: '请先登录',
        confirm: { value: '确定', action: () => {} }
      });
      return;
    }
    let req: BookingRequest = {
      memberId: this.member.id,
      scheduleId: scheduleId
    };
    try {
      await post<object>('/bookings', req);
      AlertDialog.show({
        title: '预约成功',
        message: '已成功预约该课程',
        confirm: {
          value: '确定',
          action: () => {
            this.loadCoursesTab();
            this.loadMyTab();
          }
        }
      });
    } catch (err) {
      const msg = (err as Error).message || '预约失败';
      AlertDialog.show({
        title: '预约失败',
        message: msg,
        confirm: { value: '确定', action: () => {} }
      });
    }
  }

  async handleCancelBooking(bookingId: number): Promise<void> {
    if (!this.member) {
      return;
    }
    let req: CancelBookingRequest = {
      memberId: this.member.id
    };
    try {
      await put<object>('/bookings/' + bookingId + '/cancel', req);
      AlertDialog.show({
        title: '已取消',
        message: '预约已取消',
        confirm: {
          value: '确定',
          action: () => {
            this.loadMyTab();
          }
        }
      });
    } catch (err) {
      const msg = (err as Error).message || '取消失败';
      AlertDialog.show({
        title: '取消失败',
        message: msg,
        confirm: { value: '确定', action: () => {} }
      });
    }
  }

  async handleCheckin(bookingId: number): Promise<void> {
    let req: CheckinRequest = {
      bookingId: bookingId,
      method: 1
    };
    try {
      await post<object>('/bookings/checkin', req);
      AlertDialog.show({
        title: '签到成功',
        message: '签到成功，祝您锻炼愉快！',
        confirm: {
          value: '确定',
          action: () => {
            this.loadMyTab();
          }
        }
      });
    } catch (err) {
      const msg = (err as Error).message || '签到失败';
      AlertDialog.show({
        title: '签到失败',
        message: msg,
        confirm: { value: '确定', action: () => {} }
      });
    }
  }

  handleLogout(): void {
    AlertDialog.show({
      title: '确认退出',
      message: '确定要退出登录吗？',
      confirm: {
        value: '退出',
        action: () => {
          AppStorage.delete('token');
          AppStorage.delete('member');
          try {
            router.replaceUrl({ url: 'pages/Login' });
          } catch (_) {}
        }
      },
      cancel: () => {}
    });
  }

  getGreeting(): string {
    const h = new Date().getHours();
    if (h < 6) return '夜深了';
    if (h < 9) return '早上好';
    if (h < 12) return '上午好';
    if (h < 14) return '中午好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  /* ========== UI 构建 ========== */

  build() {
    Column() {
      // 渐变顶部导航栏
      Row() {
        Column() {
          Text(this.getGreeting() + '，' + (this.member?.name ?? '用户'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White);
          Text('健康生活，从今天开始')
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.6)')
            .margin({ top: 2 });
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1);
      }
      .width('100%')
      .height(56)
      .padding({ left: 20, right: 20 })
      .linearGradient({
        direction: GradientDirection.Right,
        colors: [
          ['#1a1a2e', 0.0],
          ['#0f3460', 1.0]
        ]
      });

      // 标签页内容
      Tabs({ index: this.currentTab, barPosition: BarPosition.End }) {
        TabContent() { this.coursesTabContent(); }
          .tabBar(this.tabBuilder('课程', 0))
        TabContent() { this.myTabContent(); }
          .tabBar(this.tabBuilder('我的', 1))
        TabContent() { this.moreTabContent(); }
          .tabBar(this.tabBuilder('更多', 2))
      }
      .width('100%')
      .layoutWeight(1)
      .onChange((index: number) => {
        this.currentTab = index;
        if (index === 0) {
          this.loadCoursesTab();
        } else if (index === 1) {
          this.loadMyTab();
        }
      });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f6fa');
  }

  @Builder
  tabBuilder(label: string, index: number) {
    Column() {
      Text(label)
        .fontSize(13)
        .fontColor(this.currentTab === index ? '#1a1a2e' : '#999999')
        .fontWeight(this.currentTab === index ? FontWeight.Medium : FontWeight.Normal);
      Column()
        .width(16)
        .height(3)
        .backgroundColor(this.currentTab === index ? '#1a1a2e' : 'transparent')
        .borderRadius(2)
        .margin({ top: 4 });
    }
    .padding({ top: 8, bottom: 8 })
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  /* ---------- 课程 Tab ---------- */

  @Builder
  coursesTabContent() {
    Column() {
      if (this.loadingCourses) {
        Column() {
          LoadingProgress()
            .width(36).height(36)
            .color('#1a1a2e');
          Text('加载课程中...')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 12 });
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      } else if (this.scheduleList.length === 0) {
        Column() {
          Column() {
            Text('📅')
              .fontSize(48);
          }
          .width(80)
          .height(80)
          .backgroundColor('#f0f0f0')
          .borderRadius(40)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);

          Text('暂无可用课程')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 16 });
          Text('请稍后再来看看吧')
            .fontSize(13)
            .fontColor('#cccccc')
            .margin({ top: 4 });
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      } else {
        List({ space: 14 }) {
          ForEach(this.scheduleList, (item: ScheduleItem) => {
            ListItem() {
              this.courseCard(item);
            }
          }, (item: ScheduleItem) => String(item.id));
        }
        .width('100%')
        .height('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 8 });
      }
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  courseCard(schedule: ScheduleItem) {
    Column() {
      // 课程头部：名称 + 时间标签
      Row() {
        Text(this.courseMap[schedule.courseId] || ('课程#' + schedule.courseId))
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1a1a2e')
          .layoutWeight(1);

        Row() {
          Text(getTimeLabel(schedule.startTime))
            .fontSize(12)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium);
        }
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .backgroundColor('#e94560')
        .borderRadius(6);
      }
      .width('100%');

      // 教练和日期
      Row() {
        Row() {
          Column()
            .width(6)
            .height(6)
            .backgroundColor('#1a1a2e')
            .borderRadius(3);
          Text(this.coachMap[schedule.coachId] || ('教练#' + schedule.coachId))
            .fontSize(13)
            .fontColor('#666666')
            .margin({ left: 6 });
        }
        .margin({ right: 16 });

        Row() {
          Column()
            .width(6)
            .height(6)
            .backgroundColor('#2ecc71')
            .borderRadius(3);
          Text(schedule.classDate)
            .fontSize(13)
            .fontColor('#666666')
            .margin({ left: 6 });
        }
      }
      .width('100%')
      .margin({ top: 10 });

      // 分隔线
      Column()
        .width('100%')
        .height(1)
        .backgroundColor('#f0f0f0')
        .margin({ top: 12, bottom: 12 });

      // 底部：进度和操作
      Row() {
        // 进度信息
        Column() {
          Row() {
            Text('已约 ' + schedule.bookedCount)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(schedule.bookedCount >= schedule.actualCapacity ? '#e74c3c' : '#2ecc71');
            Text(' / ' + schedule.actualCapacity + ' 人')
              .fontSize(12)
              .fontColor('#999999');
          }
          // 进度条
          Row() {
            Column()
              .width((schedule.bookedCount / (schedule.actualCapacity || 1)) * 100 + '%')
              .height(4)
              .backgroundColor(schedule.bookedCount >= schedule.actualCapacity ? '#e74c3c' : '#2ecc71')
              .borderRadius(2);
          }
          .width('100%')
          .height(4)
          .backgroundColor('#f0f0f0')
          .borderRadius(2)
          .margin({ top: 4 });
        }
        .layoutWeight(1)
        .margin({ right: 12 });

        // 预约按钮
        Button() {
          Text(schedule.bookedCount >= schedule.actualCapacity ? '已满' : '立即预约')
            .fontSize(13)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium);
        }
        .width(88)
        .height(34)
        .backgroundColor(schedule.bookedCount >= schedule.actualCapacity ? '#cccccc' : '#1a1a2e')
        .borderRadius(8)
        .enabled(schedule.bookedCount < schedule.actualCapacity)
        .onClick(() => {
          this.handleBooking(schedule.id);
        });
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(14)
    .shadow({
      radius: 10,
      color: 'rgba(0,0,0,0.04)',
      offsetX: 0,
      offsetY: 4
    });
  }

  /* ---------- 我的 Tab ---------- */

  @Builder
  myTabContent() {
    Scroll() {
      Column() {
        if (this.loadingMy) {
          Column() {
            LoadingProgress()
              .width(36).height(36)
              .color('#1a1a2e');
            Text('加载中...')
              .fontSize(13)
              .fontColor('#999999')
              .margin({ top: 12 });
          }
          .width('100%')
          .padding({ top: 80 })
          .alignItems(HorizontalAlign.Center);
        } else {
          this.myCardSection();
          this.myBookingsSection();
          this.myRenewalsSection();
        }
      }
      .width('100%')
      .padding({ bottom: 16 });
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  myCardSection() {
    Column() {
      Row() {
        Text('我的会员卡')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1a1a2e');
      }
      .width('100%');

      if (this.cardList.length === 0) {
        // 空状态 - 引导办卡
        Column() {
          Column() {
            Text('💳')
              .fontSize(36);
          }
          .width(60)
          .height(60)
          .backgroundColor('#f5f5f5')
          .borderRadius(30)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);

          Text('暂无会员卡，请办理')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 });

          Button() {
            Text('去办卡')
              .fontSize(13)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium);
          }
          .width(100)
          .height(34)
          .backgroundColor('#1a1a2e')
          .borderRadius(8)
          .margin({ top: 8 })
          .onClick(() => {
            try { router.pushUrl({ url: 'pages/BuyCard' }); } catch (_) {}
          });
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 20, bottom: 20 })
        .backgroundColor(Color.White)
        .borderRadius(14)
        .margin({ top: 12 });
      } else {
        ForEach(this.cardList, (card: CardItem) => {
          // 信用卡风格会员卡
          Column() {
            Row() {
              Column() {
                Text('健身管家')
                  .fontSize(12)
                  .fontColor('rgba(255,255,255,0.7)');
                Text(card.remainingCount === -1 ? '时效卡' : '次卡')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .margin({ top: 4 });
              }
              .alignItems(HorizontalAlign.Start);

              Column() {
                Text(card.status === 0 ? '有效' : (card.status === 2 ? '已用尽' : '已过期'))
                  .fontSize(12)
                  .fontColor(Color.White)
                  .fontWeight(FontWeight.Medium);
              }
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor(card.status === 0 ? 'rgba(255,255,255,0.2)' : 'rgba(231,76,60,0.4)')
              .borderRadius(12);
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween);

            // 有效期
            Text('有效期: ' + card.startDate + ' ~ ' + card.endDate)
              .fontSize(11)
              .fontColor('rgba(255,255,255,0.6)')
              .width('100%')
              .margin({ top: 16 });

            // 底部：剩余次数
            if (card.remainingCount >= 0) {
              Row() {
                Text('剩余')
                  .fontSize(12)
                  .fontColor('rgba(255,255,255,0.7)');
                Text(card.remainingCount.toString())
                  .fontSize(28)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .margin({ left: 4, right: 4 });
                Text('次')
                  .fontSize(12)
                  .fontColor('rgba(255,255,255,0.7)')
                  .margin({ top: 8 });
              }
              .width('100%')
              .margin({ top: 8 });
            }
          }
          .width('100%')
          .padding(20)
          .linearGradient({
            direction: GradientDirection.Right,
            colors: [
              ['#1a1a2e', 0.0],
              ['#0f3460', 0.6],
              ['#16213e', 1.0]
            ]
          })
          .borderRadius(14)
          .margin({ top: 12 })
          .shadow({
            radius: 16,
            color: 'rgba(15,52,96,0.25)',
            offsetX: 0,
            offsetY: 6
          });
        });
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16 });
  }

  @Builder
  myBookingsSection() {
    Column() {
      Row() {
        Text('我的预约')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1a1a2e');
      }
      .width('100%');

      if (this.bookingList.length === 0) {
        Column() {
          Text('暂无预约记录')
            .fontSize(14)
            .fontColor('#999999')
            .padding({ top: 16, bottom: 16 });
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center);
      } else {
        ForEach(this.bookingList, (booking: BookingItem) => {
          Column() {
            Row() {
              // 状态标签
              Text(getBookingStatusText(booking.status))
                .fontSize(11)
                .fontColor(getBookingStatusColor(booking.status))
                .fontWeight(FontWeight.Medium)
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .backgroundColor(getBookingStatusBg(booking.status))
                .borderRadius(4);

              if (booking.status === 0) {
                Row() {
                  Button('签到')
                    .fontSize(12)
                    .fontColor(Color.White)
                    .backgroundColor('#2ecc71')
                    .borderRadius(6)
                    .height(28)
                    .onClick(() => { this.handleCheckin(booking.id); });

                  Button('取消')
                    .fontSize(12)
                    .fontColor('#e74c3c')
                    .backgroundColor('#fff5f5')
                    .borderRadius(6)
                    .height(28)
                    .margin({ left: 8 })
                    .onClick(() => { this.handleCancelBooking(booking.id); });
                }
              }
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween);

            Text(this.scheduleDetailMap[booking.scheduleId] || ('排课#' + booking.scheduleId))
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1a1a2e')
              .width('100%')
              .margin({ top: 8 });
          }
          .width('100%')
          .padding(14)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ top: 10 })
          .shadow({
            radius: 6,
            color: 'rgba(0,0,0,0.03)',
            offsetX: 0,
            offsetY: 2
          });
        });
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12 });
  }

  @Builder
  myRenewalsSection() {
    Column() {
      Row() {
        Text('续费记录')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1a1a2e');
      }
      .width('100%');

      if (this.renewalList.length === 0) {
        Column() {
          Text('暂无续费记录')
            .fontSize(14)
            .fontColor('#999999')
            .padding({ top: 16, bottom: 16 });
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center);
      } else {
        ForEach(this.renewalList, (record: RenewalRecord) => {
          Row() {
            Column() {
              Text('¥' + record.amount.toFixed(2))
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#e94560');
              Text(record.renewalDate != null ? record.renewalDate.substring(0, 10) : '')
                .fontSize(11)
                .fontColor('#999999')
                .margin({ top: 2 });
            }
            .alignItems(HorizontalAlign.Start);

            Text(record.remark || '续费')
              .fontSize(13)
              .fontColor('#666666');
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ top: 12, bottom: 12 })
          .border({ width: { bottom: 1 }, color: { bottom: "#f5f5f5" } });
        });
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(14)
    .margin({ left: 16, right: 16, top: 12, bottom: 16 })
    .shadow({
      radius: 10,
      color: 'rgba(0,0,0,0.04)',
      offsetX: 0,
      offsetY: 4
    });
  }

  /* ---------- 更多 Tab ---------- */

  @Builder
  moreTabContent() {
    Scroll() {
      Column() {
        // 用户信息卡片
        Column() {
          Column() {
            Column()
              .width(64)
              .height(64)
              .backgroundColor('#e0e0e0')
              .borderRadius(32);
            Text(this.member?.name ?? '用户')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .margin({ top: 12 });
            Text('手机号: ' + (this.member?.phone ?? '--'))
              .fontSize(13)
              .fontColor('rgba(255,255,255,0.7)')
              .margin({ top: 4 });
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 32, bottom: 24 });
        }
        .width('100%')
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [
            ['#1a1a2e', 0.0],
            ['#0f3460', 1.0]
          ]
        })
        .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 16, bottomRight: 16 });

        // 功能入口
        Column() {
          // 办卡中心
          Row() {
            Column()
              .width(36)
              .height(36)
              .backgroundColor('#fff5f5')
              .borderRadius(10)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center);
            Column() {
              Text('办卡中心')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1a1a2e');
              Text('查看和购买会员卡')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 2 });
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 12 })
            .layoutWeight(1);

            Text('>')
              .fontSize(16)
              .fontColor('#cccccc');
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .onClick(() => {
            try { router.pushUrl({ url: 'pages/BuyCard' }); } catch (_) {}
          });

          // 退出登录
          Row() {
            Column()
              .width(36)
              .height(36)
              .backgroundColor('#fff5f5')
              .borderRadius(10)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center);
            Column() {
              Text('退出登录')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#e74c3c');
              Text('注销当前账号')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 2 });
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 12 })
            .layoutWeight(1);

            Text('>')
              .fontSize(16)
              .fontColor('#cccccc');
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ top: 12 })
          .onClick(() => {
            this.handleLogout();
          });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 24 });

        Text('v1.0.0')
          .fontSize(12)
          .fontColor('#cccccc')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 32, bottom: 16 });
      }
      .width('100%');
    }
    .width('100%')
    .height('100%');
  }
}


