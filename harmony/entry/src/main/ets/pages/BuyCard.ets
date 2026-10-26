import router from '@ohos.router';
import { get, post } from '../utils/HttpUtil';
import { PurchaseCardRequest } from '../utils/HttpUtil';

interface CardTemplate {
  id: number;
  name: string;
  type: number;
  durationDays: number;
  totalCount: number;
  price: number;
  status: number;
}

@Entry
@Component
struct BuyCard {
  @State memberId: number = 0;
  @State templateList: CardTemplate[] = [];
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
      this.loadTemplates();
    } else {
      this.loading = false;
    }
  }

  async loadTemplates(): Promise<void> {
    this.loading = true;
    try {
      const templates = await get<CardTemplate[]>('/cards/templates');
      this.templateList = templates.filter(t => t.status === 0);
    } catch (err) {
      const msg = (err as Error).message || '加载卡模板失败';
      AlertDialog.show({
        title: '提示',
        message: msg,
        confirm: { value: '确定', action: () => {} }
      });
    }
    this.loading = false;
  }

  async handlePurchase(templateId: number): Promise<void> {
    AlertDialog.show({
      title: '确认办卡',
      message: '确定要购买该会员卡吗？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      confirm: {
        value: '确认购买',
        action: async () => {
          let req: PurchaseCardRequest = {
            memberId: this.memberId,
            templateId: templateId
          };
          try {
            await post<object>('/cards/purchase', req);
            AlertDialog.show({
              title: '办卡成功',
              message: '恭喜您成功办理会员卡！',
              confirm: {
                value: '确定',
                action: () => {
                  router.back();
                }
              }
            });
          } catch (err) {
            const msg = (err as Error).message || '办卡失败';
            AlertDialog.show({
              title: '办卡失败',
              message: msg,
              confirm: { value: '确定', action: () => {} }
            });
          }
        }
      }
    });
  }

  getTemplateTypeLabel(type: number): string {
    return type === 0 ? '时效卡' : '次卡';
  }

  getTemplateDesc(template: CardTemplate): string {
    if (template.type === 0) {
      return '有效期内不限次数';
    } else {
      return '有效期 ' + template.durationDays + ' 天，共 ' + template.totalCount + ' 次';
    }
  }

  getTemplateValidDays(template: CardTemplate): string {
    return '有效期 ' + template.durationDays + ' 天';
  }

  build() {
    Column() {
      Row() {
        Text('办卡中心')
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
      } else if (this.templateList.length === 0) {
        Column() {
          Column() {
            Text('💳')
              .fontSize(48);
          }
          .width(80)
          .height(80)
          .backgroundColor('#f5f5f5')
          .borderRadius(40)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);

          Text('暂无可办卡类型')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 16 });
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      } else {
        List({ space: 16 }) {
          ForEach(this.templateList, (template: CardTemplate) => {
            ListItem() {
              Column() {
                // 卡片类型标签
                Row() {
                  Text(this.getTemplateTypeLabel(template.type))
                    .fontSize(12)
                    .fontColor(Color.White)
                    .fontWeight(FontWeight.Medium)
                    .padding({ left: 10, right: 10, top: 3, bottom: 3 })
                    .backgroundColor('#e94560')
                    .borderRadius(6);
                }
                .width('100%')
                .justifyContent(FlexAlign.Start);

                // 卡名
                Text(template.name)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1a1a2e')
                  .width('100%')
                  .margin({ top: 12 });

                // 说明
                Text(this.getTemplateDesc(template))
                  .fontSize(13)
                  .fontColor('#666666')
                  .width('100%')
                  .margin({ top: 6 });

                // 分隔
                Column()
                  .width('100%')
                  .height(1)
                  .backgroundColor('#f0f0f0')
                  .margin({ top: 16, bottom: 16 });

                // 价格和购买按钮
                Row() {
                  Row() {
                    Text('¥')
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#e94560')
                      .margin({ top: 4 });
                    Text((template.price != null ? template.price.toFixed(2) : '0.00'))
                      .fontSize(28)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#e94560');
                  }
                  .alignItems(VerticalAlign.Bottom);

                  Button() {
                    Text('立即购买')
                      .fontSize(14)
                      .fontColor(Color.White)
                      .fontWeight(FontWeight.Medium);
                  }
                  .width(100)
                  .height(38)
                  .backgroundColor('#1a1a2e')
                  .borderRadius(10)
                  .shadow({
                    radius: 6,
                    color: 'rgba(26,26,46,0.2)',
                    offsetX: 0,
                    offsetY: 3
                  })
                  .onClick(() => {
                    this.handlePurchase(template.id);
                  });
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
                .alignItems(VerticalAlign.Center);
              }
              .width('100%')
              .padding(20)
              .backgroundColor(Color.White)
              .borderRadius(14)
              .shadow({
                radius: 10,
                color: 'rgba(0,0,0,0.04)',
                offsetX: 0,
                offsetY: 4
              });
            }
          }, (template: CardTemplate) => String(template.id));
        }
        .width('100%')
        .height('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 8 });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f6fa');
  }
}
