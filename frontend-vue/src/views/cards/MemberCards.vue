<template>
  <a-card title="会员卡管理">
    <template #extra>
      <a-space>
        <a-input-search v-model:value="searchKeyword" placeholder="搜索持卡人姓名/手机号" style="width: 260px" @search="fetchCards" allowClear />
        <a-button type="primary" @click="openIssue">
          <template #icon><plus-outlined /></template>发卡
        </a-button>
      </a-space>
    </template>
    <a-table rowKey="id" :columns="columns" :dataSource="displayCards" :loading="loading" :pagination="{ pageSize: 20 }">
      <template #bodyCell="{ column, record }">
        <template v-if="column.dataIndex === 'remainingCount'">
          {{ record.remainingCount === -1 ? "不限次" : record.remainingCount }}
        </template>
        <template v-else-if="column.dataIndex === 'templateName'">{{ getTemplateName(record.templateId) }}</template>
        <template v-else-if="column.dataIndex === 'memberName'">
          {{ getMemberName(record.memberId) }}
        </template>
        <template v-else-if="column.dataIndex === 'status'">
          <a-tag :color="getCardColor(record.status)">{{ getCardLabel(record.status) }}</a-tag>
        </template>
        <template v-else-if="column.key === 'action'">
          <a-space>
            <a-button type="link" @click="showRenewals(record.memberId)">记录</a-button>
            <a-button type="link" danger @click="handleDisable(record.id)" v-if="record.status === 0">停用</a-button>
            <a-button type="link" @click="handleReactivate(record.id)" v-if="record.status === 3">重启</a-button>
            <a-popconfirm title="确定永久删除该会员卡？无法恢复！" @confirm="handleDelete(record.id)">
              <a-button type="link" danger>删除</a-button>
            </a-popconfirm>
          </a-space>
        </template>
      </template>
    </a-table>

    <a-modal v-model:open="issueOpen" title="发卡" @ok="handleIssue" destroyOnClose>
      <a-form ref="issueFormRef" :model="issueForm" layout="vertical">
        <a-form-item name="memberId" label="会员" :rules="[{ required: true }]">
          <a-select v-model:value="issueForm.memberId" showSearch
            :filterOption="(input: string, opt: any) => (opt.label || '').includes(input)"
            :options="memberOptions" />
        </a-form-item>
        <a-form-item name="templateId" label="卡模板" :rules="[{ required: true }]">
          <a-select v-model:value="issueForm.templateId"
            :options="templateOptions" />
        </a-form-item>
      </a-form>
    </a-modal>

    <a-modal v-model:open="renewalsOpen" title="续费记录" :footer="null" width="700px" destroyOnClose>
      <a-table rowKey="id" :columns="renewalsColumns" :dataSource="renewals" :pagination="false" size="small" />
    </a-modal>
  </a-card>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from "vue";
import { message } from "ant-design-vue";
import { PlusOutlined } from "@ant-design/icons-vue";
import { memberCardApi } from "../../api/memberCards";
import { memberApi } from "../../api/members";
import { cardTemplateApi } from "../../api/cardTemplates";
import type { MemberCard, RenewalRecord } from "../../api/memberCards";
import type { CardTemplate } from "../../api/cardTemplates";
import type { MemberInfo } from "../../api/members";

const cards = ref<MemberCard[]>([]);
const loading = ref(false);
const issueOpen = ref(false);
const renewalsOpen = ref(false);
const renewals = ref<RenewalRecord[]>([]);
const memberOptions = ref<{ value: number; label: string }[]>([]);
const templateOptions = ref<{ value: number; label: string }[]>([]);
const issueForm = reactive({ memberId: undefined as number | undefined, templateId: undefined as number | undefined });
const searchKeyword = ref("");
const memberMap = ref<Record<number, string>>({});
const templateMap = ref<Record<number, string>>({});

const cardStatusMap: Record<number, [string, string]> = { 0: ["正常", "green"], 1: ["过期", "red"], 2: ["用完", "orange"], 3: ["已停用", "purple"] };
function getCardColor(s: number) { return (cardStatusMap[s] || ["未知", "default"])[1]; }
function getCardLabel(s: number) { return (cardStatusMap[s] || ["未知", "default"])[0]; }
function getMemberName(memberId: number): string { return memberMap.value[memberId] || "会员#" + memberId; }
function getTemplateName(templateId: number): string { return templateMap.value[templateId] || '模板#' + templateId; }

const columns = [
  { title: "ID", dataIndex: "id", key: "id", width: 60 },
  { title: "持卡人", dataIndex: "memberName", key: "memberName", width: 120 },
  { title: "卡名称", dataIndex: "templateName", key: "templateName", width: 120 },
  { title: "开始日期", dataIndex: "startDate", key: "startDate" },
  { title: "结束日期", dataIndex: "endDate", key: "endDate" },
  { title: "剩余次数", dataIndex: "remainingCount", key: "remainingCount", width: 90 },
  { title: "状态", dataIndex: "status", key: "status", width: 80 },
  { title: "操作", key: "action", width: 200 },
];

const renewalsColumns = [
  { title: "记录ID", dataIndex: "id", key: "id", width: 70 },
  { title: "会员ID", dataIndex: "memberId", key: "memberId", width: 70 },
  { title: "金额", dataIndex: "amount", key: "amount", customRender: ({ text }: { text: number }) => "¥" + text.toFixed(2) },
  { title: "支付方式", dataIndex: "paymentMethod", key: "paymentMethod", width: 90,
    customRender: ({ text }: { text: number }) => ({ 0: "现金", 1: "微信", 2: "支付宝", 3: "银行卡" }[text] || "未知") },
  { title: "备注", dataIndex: "remark", key: "remark" },
  { title: "时间", dataIndex: "createdAt", key: "createdAt" },
];

const displayCards = computed(() => {
  if (!searchKeyword.value) return cards.value;
  const kw = searchKeyword.value.toLowerCase();
  return cards.value.filter((c) => {
    const name = (memberMap.value[c.memberId] || "").toLowerCase();
    const idStr = String(c.memberId);
    return name.includes(kw) || idStr.includes(kw);
  });
});

async function fetchCards() {
  loading.value = true;
  try {
    const params: any = { page: 1, size: 200 };
    if (searchKeyword.value) params.keyword = searchKeyword.value;
    const mRes = await memberApi.list(params);
    const members = mRes.data.records;
    const mm: Record<number, string> = {};
    for (const m of members) { mm[m.id] = m.name + "(" + m.phone + ")"; }
    memberMap.value = mm;
    const all = await Promise.all(members.map((m: MemberInfo) => memberApi.getCards(m.id)));
    cards.value = all.flatMap((r) => r.data);
  } finally {
    loading.value = false;
  }
}

async function fetchOptions() {
  const [mRes, tRes] = await Promise.all([memberApi.list({ page: 1, size: 200 }), cardTemplateApi.list()]);
  memberOptions.value = mRes.data.records.map((m: MemberInfo) => ({ value: m.id, label: m.name + "(" + m.phone + ")" }));
  templateOptions.value = tRes.data.map((t: CardTemplate) => ({ value: t.id, label: t.name + " ¥" + t.price }));
  const tm: Record<number, string> = {};
  for (const t of tRes.data) { tm[t.id] = t.name; }
  templateMap.value = tm;
}

async function handleIssue() {
  try {
    await memberCardApi.issue(issueForm as any);
    message.success("发卡成功");
    issueOpen.value = false;
    issueForm.memberId = undefined;
    issueForm.templateId = undefined;
    fetchCards();
  } catch (e: any) {
    message.error(e.message || "发卡失败");
  }
}

async function showRenewals(memberId?: number) {
  try {
    const res = await memberCardApi.renewals({ memberId });
    renewals.value = res.data;
    renewalsOpen.value = true;
  } catch (e: any) {
    message.error(e.message || "加载失败");
  }
}

async function handleReactivate(id: number) {
  try {
    await memberCardApi.reactivate(id);
    message.success('已重启');
    fetchCards();
  } catch (e: any) {
    message.error(e.message || '操作失败');
  }
}

async function handleDisable(id: number) {
  try {
    await memberCardApi.disable(id);
    message.success("已停用");
    fetchCards();
  } catch (e: any) {
    message.error(e.message || "操作失败");
  }
}

async function handleDelete(id: number) {
  try {
    await memberCardApi.delete(id);
    message.success("已删除");
    fetchCards();
  } catch (e: any) {
    message.error(e.message || "操作失败");
  }
}

function openIssue() {
  issueForm.memberId = undefined;
  issueForm.templateId = undefined;
  issueOpen.value = true;
}

onMounted(() => { fetchCards(); fetchOptions(); });
</script>