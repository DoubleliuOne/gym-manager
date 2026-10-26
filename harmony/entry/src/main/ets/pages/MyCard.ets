import router from '@ohos.router';
import { get, post, put } from '../utils/HttpUtil';
import { CancelBookingRequest, CheckinRequest } from '../utils/HttpUtil';

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

@Entry
@Component
struct MyCard {
  @State memberId: number = 0;
  @State cardList: CardItem[] = [];
  @State bookingList: BookingItem[] = [];
  @State scheduleDetailMap: Record<number, string> = {};
  @State renewalList: RenewalRecord[] = [];
  @State loading: boolean = true;

  aboutToAppear(): void {
    this.checkAuth();
  }

  checkAuth(): void {
    const token = AppStorage.get<string>('token');
    if (!token) {
      try {
        router.replaceUrl({ url: 'pages/Login' });
      } catch (_) {}
      return;
    }
    const mid = AppStorage.get<number>('memberId');
    if (mid) {
      this.memberId = mid;
      this.loadData();
    } else {
      this.loading = false;
    }
  }

  async loadData(): Promise<void> {
    this.loading = true;
    try {
      const cards = await get<CardItem[]>('/members/' + this.memberId + '/cards');
      const bookings = await get<BookingItem[]>('/bookings/member/' + this.memberId);
      const renewals = await get<RenewalRecord[]>('/statistics/member-renewals?memberId=' + this.memberId);

      this.cardList = cards;
      this.bookingList = bookings;
      this.renewalList = renewals;

      let sdm: Record<number, string> = {};
      for (let i = 0; i < bookings.length; i++) {
        try {
          const sd = await get<ScheduleItem>('/schedules/' + bookings[i].scheduleId);
          try {
            const course = await get<CourseItem>('/courses/' + sd.courseId);
            sdm[bookings[i].scheduleId] = course.name + ' ' + sd.classDate.replace(/-/g, '/') + ' ' + sd.startTime.substring(0, 5);
          } catch (_) {
            sdm[bookings[i].scheduleId] = '课程#' + sd.courseId + ' ' + sd.classDate;
          }
        } catch (_) {
          sdm[bookings[i].scheduleId] = '排课#' + bookings[i].scheduleId;
        }
      }
      this.scheduleDetailMap = sdm;
    } catch (err) {
      const msg = (err as Error).message || '加载数据失败';
      AlertDialog.show({
        title: '提示',
        message: msg,
        confirm: { value: '确定', action: () => {} }
      });
    }
    this.loading = false;
  }

  async handleCancelBooking(bookingId: number): Promise<void> {
    let req: CancelBookingRequest = {
      memberId: this.memberId
    };
    try {
      await put<object>('/bookings/' + bookingId + '/cancel', req);
      AlertDialog.show({
        title: '已取消',
        message: '预约已取消',
        confirm: {
          value: '确定',
          action: () => { this.loadData(); }
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
          action: () => { this.loadData(); }
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

  build() {
    Column() {
      Row() {
        Text('我的')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff');
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

      if (this.loading) {
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
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      } else {
        Scroll() {
          Column() {
            // 会员卡
            Column() {
              Row() {
                Text('会员卡')
                  .fontSize(17).fontWeight(FontWeight.Bold).fontColor('#1a1a2e');
              }
              .width('100%');

              if (this.cardList.length === 0) {
                Text('暂无会员卡，请联系健身房办理')
                  .fontSize(14).fontColor('#999999').margin({ top: 12 });
              } else {
                ForEach(this.cardList, (card: CardItem) => {
                  Column() {
                    Row() {
                      Column() {
                        Text('健身管家')
                          .fontSize(11)
                          .fontColor('rgba(255,255,255,0.6)');
                        Text(card.remainingCount === -1 ? '时效卡' : '次卡')
                          .fontSize(17)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(Color.White)
                          .margin({ top: 2 });
                      }
                      .alignItems(HorizontalAlign.Start);

                      Text(card.status === 0 ? '有效' : (card.status === 2 ? '已用尽' : '已过期'))
                        .fontSize(12)
                        .fontColor(Color.White)
                        .padding({ left: 10, right: 10, top: 3, bottom: 3 })
                        .backgroundColor(card.status === 0 ? 'rgba(255,255,255,0.2)' : 'rgba(231,76,60,0.4)')
                        .borderRadius(10);
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween);

                    Text('有效期: ' + card.startDate + ' ~ ' + card.endDate)
                      .fontSize(11)
                      .fontColor('rgba(255,255,255,0.6)')
                      .width('100%')
                      .margin({ top: 14 });

                    if (card.remainingCount >= 0) {
                      Row() {
                        Text('剩余 ')
                          .fontSize(12)
                          .fontColor('rgba(255,255,255,0.7)');
                        Text(card.remainingCount.toString())
                          .fontSize(26)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(Color.White);
                        Text(' 次')
                          .fontSize(12)
                          .fontColor('rgba(255,255,255,0.7)')
                          .margin({ top: 6 });
                      }
                      .width('100%')
                      .margin({ top: 6 });
                    }
                  }
                  .width('100%')
                  .padding(18)
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
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(14)
            .shadow({
              radius: 10,
              color: 'rgba(0,0,0,0.04)',
              offsetX: 0,
              offsetY: 4
            });

            // 预约
            Column() {
              Row() {
                Text('我的预约')
                  .fontSize(17).fontWeight(FontWeight.Bold).fontColor('#1a1a2e')
                  .margin({ top: 12 });
              }
              .width('100%');

              if (this.bookingList.length === 0) {
                Text('暂无预约记录')
                  .fontSize(14).fontColor('#999999').margin({ top: 12 });
              } else {
                ForEach(this.bookingList, (booking: BookingItem) => {
                  Column() {
                    Text(this.scheduleDetailMap[booking.scheduleId] || ('排课#' + booking.scheduleId))
                      .fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1a1a2e');

                    Text(getBookingStatusText(booking.status))
                      .fontSize(11)
                      .fontColor(getBookingStatusColor(booking.status))
                      .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                      .backgroundColor(getBookingStatusBg(booking.status))
                      .borderRadius(4)
                      .margin({ top: 6 });

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
                      .width('100%')
                      .justifyContent(FlexAlign.End)
                      .margin({ top: 8 });
                    }
                  }
                  .width('100%')
                  .padding(14)
                  .backgroundColor('#f8f9fa')
                  .borderRadius(12)
                  .margin({ top: 10 });
                });
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(14)
            .margin({ top: 12 })
            .shadow({
              radius: 10,
              color: 'rgba(0,0,0,0.04)',
              offsetX: 0,
              offsetY: 4
            });

            // 续费
            Column() {
              Row() {
                Text('续费记录')
                  .fontSize(17).fontWeight(FontWeight.Bold).fontColor('#1a1a2e')
                  .margin({ top: 12 });
              }
              .width('100%');

              if (this.renewalList.length === 0) {
                Text('暂无续费记录')
                  .fontSize(14).fontColor('#999999').margin({ top: 12 });
              } else {
                ForEach(this.renewalList, (record: RenewalRecord) => {
                  Row() {
                    Text('¥' + record.amount.toFixed(2))
                      .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#e94560');
                    Text(record.remark || '续费')
                      .fontSize(13).fontColor('#666666')
                      .layoutWeight(1)
                      .margin({ left: 12 });
                    Text(record.renewalDate != null ? record.renewalDate.substring(0, 10) : '')
                      .fontSize(12).fontColor('#999999');
                  }
                  .width('100%')
                  .padding({ top: 10, bottom: 10 })
                  .border({ width: { bottom: 1 }, color: { bottom: "#f5f5f5" } });
                });
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(14)
            .margin({ top: 12, bottom: 16 })
            .shadow({
              radius: 10,
              color: 'rgba(0,0,0,0.04)',
              offsetX: 0,
              offsetY: 4
            });
          }
          .width('100%')
          .padding(16);
        }
        .width('100%')
        .height('100%');
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f6fa');
  }
}


