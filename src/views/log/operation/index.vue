<template>
  <div class="system-user-container app-container">
    <el-card shadow="always">
      <!-- 查询 -->
      <el-form
          :model="state.queryParams"
          ref="queryForm"
          :inline="true"
          label-width="68px"
      >
        <el-form-item label="系统模块" prop="title">
          <el-input
              placeholder="请输入系统模块模糊查询"
              clearable
              @keyup.enter="handleQuery"
              style="width: 240px"
              v-model="state.queryParams.title"
          />
        </el-form-item>
        <el-form-item label="操作人员" prop="operName">
          <el-input
              placeholder="请输入操作人员模糊查询"
              clearable
              @keyup.enter="handleQuery"
              style="width: 240px"
              v-model="state.queryParams.operName"
          />
        </el-form-item>
        <el-form-item label="类型" prop="businessType">
          <el-select
              v-model="state.queryParams.businessType"
              placeholder="操作类型"
              clearable
              style="width: 240px"
          >
            <el-option
                v-for="dict in state.typeOptions"
                :key="dict.dictValue"
                :label="dict.dictLabel"
                :value="dict.dictValue"
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" plain @click="handleQuery">
            <SvgIcon name="elementSearch"/>
            搜索
          </el-button>
          <el-button @click="resetQuery">
            <SvgIcon name="elementRefresh"/>
            重置
          </el-button>
        </el-form-item>
      </el-form>
    </el-card>
    <el-card class="box-card">
      <template #header>
        <div class="card-header">
          <span class="card-header-text">操作日志</span>
          <div>
            <el-button
                type="danger"
                plain
                :disabled="state.multiple"
                @click="onTabelRowDel"
                v-auth="'log:operation:delete'"
            >
              <SvgIcon name="elementDelete"/>
              删除
            </el-button>
            <el-button
                type="danger"
                plain
                @click="handleClean"
                v-auth="'log:operation:clean'"
            >
              <SvgIcon name="elementDelete"/>
              清空
            </el-button>
          </div>
        </div>
      </template>

      <!--数据表格-->
      <el-table
          v-loading="state.loading"
          :data="state.tableData"
          @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="55" align="center"/>
        <el-table-column label="日志编号" align="center" prop="operId"/>
        <el-table-column label="系统模块" align="center" prop="title"/>
        <el-table-column
            label="操作类型"
            align="center"
            prop="businessType"
            :formatter="typeFormat"
        />
        <el-table-column label="请求方法" align="center" prop="method"/>
        <el-table-column label="操作人员" align="center" prop="operName"/>
        <el-table-column
            label="主机"
            align="center"
            prop="operIp"
            width="130"
            :show-overflow-tooltip="true"
        />
        <el-table-column
            label="操作地点"
            align="center"
            prop="operLocation"
            :show-overflow-tooltip="true"
        />
        <el-table-column
            label="操作状态"
            align="center"
            prop="status"
        >
          <template #default="scope">
            <el-tag
                :type="scope.row.status === '1' ? 'danger' : 'success'"
                disable-transitions
            >{{ statusFormat(scope.row) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column
            label="操作日期"
            align="center"
        >
          <template #default="scope">
            <span>{{ dateStrFormat(scope.row.createTime) }}</span>
          </template>
        </el-table-column>
        <el-table-column
            label="操作"
            align="center"
            class-name="small-padding fixed-width"
        >
          <template #default="scope">
            <el-button
                text type="primary"
                @click="handleView(scope.row)"
            >
              <SvgIcon name="elementView"/>
              详细
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页设置-->
      <div v-show="state.total > 0">
        <el-divider></el-divider>
        <el-pagination
            background
            :total="state.total"
            :current-page="state.queryParams.pageNum"
            :page-sizes="[10, 20, 30, 40]"
            :page-size="state.queryParams.pageSize"
            layout="total, sizes, prev, pager, next, jumper"
            @size-change="handleSizeChange"
            @current-change="handleCurrentChange"
        />
      </div>
    </el-card>
    <!-- 操作日志详细 -->
    <el-dialog
        title="操作日志详细"
        v-model="state.open"
        width="920px"
        class="oper-detail-dialog"
        center
        append-to-body
    >
      <el-descriptions class="oper-desc" :column="2" border>
        <el-descriptions-item label="操作模块">
          {{ state.modelForm.title }} / {{ typeFormat(state.modelForm) }}
        </el-descriptions-item>
        <el-descriptions-item label="操作时间">
          {{ dateStrFormat(state.modelForm.createTime) }}
        </el-descriptions-item>
        <el-descriptions-item label="操作人员">
          {{ state.modelForm.operName }}
        </el-descriptions-item>
        <el-descriptions-item label="操作状态">
          <el-tag
              size="small"
              effect="light"
              disable-transitions
              :type="state.modelForm.status === '1' ? 'danger' : 'success'"
          >{{ statusFormat(state.modelForm) }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="请求地址" :span="2">
          <span class="oper-method">{{ state.modelForm.method }}</span>
          <span class="oper-url">{{ state.modelForm.operUrl }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="来源主机">
          {{ state.modelForm.operIp }} / {{ state.modelForm.operLocation }}
        </el-descriptions-item>
        <el-descriptions-item label="Trace Id">
          {{ state.modelForm.traceId || '-' }}
        </el-descriptions-item>
        <el-descriptions-item v-if="state.modelForm.status === '1'" label="异常信息" :span="2">
          <span class="oper-error">{{ state.modelForm.errorMsg }}</span>
        </el-descriptions-item>
      </el-descriptions>

      <div class="flow-panel" v-if="flowSteps.length || state.modelForm.flow">
        <div class="flow-panel__head">
          <div class="flow-panel__title">
            <span class="flow-panel__mark"></span>
            执行链路
            <el-tag
                v-if="flowSteps.length"
                size="small"
                effect="dark"
                disable-transitions
                :type="flowSummary.fail ? 'danger' : 'success'"
            >{{ flowSummary.fail ? 'FAILED' : 'SUCCESS' }}</el-tag>
          </div>
          <div class="flow-panel__metrics" v-if="flowSteps.length">
            <span><em>{{ flowSummary.total }}</em> 步</span>
            <span class="is-ok"><em>{{ flowSummary.ok }}</em> 成功</span>
            <span class="is-fail" v-if="flowSummary.fail"><em>{{ flowSummary.fail }}</em> 失败</span>
            <span class="is-skip" v-if="flowSummary.skip"><em>{{ flowSummary.skip }}</em> 跳过</span>
            <span><em>{{ flowSummary.cost }}</em> ms</span>
          </div>
          <span class="flow-panel__hint" v-else>历史日志，仅保留文本记录</span>
        </div>

        <div class="flow-steps" v-if="flowSteps.length">
          <div
              class="flow-step"
              v-for="(step, index) in flowSteps"
              :key="index"
              :class="'is-' + String(step.status).toLowerCase()"
          >
            <div class="flow-step__rail">
              <span class="flow-step__dot">{{ index + 1 }}</span>
              <span class="flow-step__line" v-if="index < flowSteps.length - 1"></span>
            </div>
            <div class="flow-step__body">
              <div class="flow-step__title">
                <span class="flow-step__name">{{ step.name }}</span>
                <el-tag
                    size="small"
                    effect="light"
                    disable-transitions
                    :type="statusType(step.status)"
                >{{ statusText(step.status) }}</el-tag>
                <span class="flow-step__cost" v-if="step.costMs">{{ step.costMs }} ms</span>
              </div>
              <div class="flow-step__fields" v-if="step.fields && step.fields.length">
                <div class="flow-field" v-for="field in step.fields" :key="field.label">
                  <span class="flow-field__label">{{ field.label }}</span>
                  <span class="flow-field__value">{{ field.value }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <el-collapse class="flow-raw" v-if="state.modelForm.flow">
          <el-collapse-item title="ASCII 流程图（可复制到终端）" name="raw">
            <div class="flow-raw__actions">
              <el-button size="small" text type="primary" @click="copyFlow">复制</el-button>
            </div>
            <pre class="flow-chart">{{ state.modelForm.flow }}</pre>
          </el-collapse-item>
        </el-collapse>
      </div>

      <template #footer>
        <span class="dialog-footer">
          <el-button @click="state.open = false">关 闭</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script lang="ts" setup name="Operlog">
import {reactive, onMounted, getCurrentInstance, computed} from "vue";
import {
  listOperInfo,
  delOperInfo,
  cleanOpernfo,
} from "@/api/log/oper";
import {ElMessageBox, ElMessage} from "element-plus";

const {proxy} = getCurrentInstance() as any;
// 结构化链路步骤，用于渲染流程图
const flowSteps = computed<any[]>(() => {
  const raw = state.modelForm.flowData;
  if (!raw) return [];
  try {
    return JSON.parse(raw);
  } catch (e) {
    return [];
  }
});
const flowSummary = computed(() => {
  const steps = flowSteps.value;
  return {
    total: steps.length,
    ok: steps.filter((s) => s.status === 'OK').length,
    fail: steps.filter((s) => s.status === 'FAIL').length,
    skip: steps.filter((s) => s.status === 'SKIP').length,
    cost: steps.reduce((sum, s) => sum + (s.costMs || 0), 0),
  };
});
const statusType = (status: string) => {
  if (status === 'OK') return 'success';
  if (status === 'FAIL') return 'danger';
  return 'info';
};
const statusText = (status: string) => {
  if (status === 'OK') return '成功';
  if (status === 'FAIL') return '失败';
  return '跳过';
};
const copyFlow = async () => {
  try {
    await navigator.clipboard.writeText(state.modelForm.flow || '');
    ElMessage.success('已复制到剪贴板');
  } catch (e) {
    ElMessage.warning('复制失败，请手动选择文本');
  }
};
const state = reactive({
  // 遮罩层
  loading: true,
  // 总条数
  total: 0,
  // 列表表格数据
  tableData: [],
  // 选中数组
  ids: [],
  // 非单个禁用
  single: true,
  // 非多个禁用
  multiple: true,
  // 弹出层标题
  title: "",
  // 是否显示弹出层
  open: false,
  // 表单参数
  modelForm: {},
  // 类型数据字典
  typeOptions: [],
  // 类型数据字典
  statusOptions: [],
  // 查询参数
  queryParams: {
    pageNo: 1,
    pageSize: 10,
    title: undefined,
    operName: undefined,
    businessType: undefined,
  },
});

/** 查询定时任务列表 */
const handleQuery = () => {
  state.loading = true;
  listOperInfo(state.queryParams).then(
      (response) => {
        state.tableData = response.data.data;
        state.total = response.data.total;
        state.loading = false;
      }
  );
};

/** 重置按钮操作 */
const resetQuery = () => {
  state.queryParams.title = undefined;
  state.queryParams.operName = undefined;
  state.queryParams.businessType = undefined;
  handleQuery();
};

/** 清空按钮操作 */
const handleClean = () => {
  ElMessageBox({
    message: "是否确认清空所有操作日志数据项?",
    title: "警告",
    showCancelButton: true,
    confirmButtonText: "确定",
    cancelButtonText: "取消",
    type: "warning",
  })
      .then(function () {
        return cleanOpernfo();
      })
      .then(() => {
        handleQuery();
        ElMessage.success("清空成功");
      });
};

/** 删除按钮操作 */
const onTabelRowDel = (row: any) => {
  const operIds = row.operId || state.ids;
  ElMessageBox({
    message: '是否确认删除日志编号为"' + operIds + '"的数据项?',
    title: "警告",
    showCancelButton: true,
    confirmButtonText: "确定",
    cancelButtonText: "取消",
    type: "warning",
  }).then(function () {
    return delOperInfo(operIds).then((res:any) => {
      if (res.code === 200){
        handleQuery();
        ElMessage.success("删除成功");
      }else {
        ElMessage.error("删除失败");
      }
    });
  });
};

/** 详细按钮操作 */
const handleView = (row: any) => {
  state.open = true;
  state.modelForm = row;
};

//分页页面大小发生变化
const handleSizeChange = (val: any) => {
  state.queryParams.pageSize = val;
  handleQuery();
};
//当前页码发生变化
const handleCurrentChange = (val: any) => {
  state.queryParams.pageNo = val;
  handleQuery();
};

// 操作日志状态字典翻译
const statusFormat = (row: any, column: any) => {
  return proxy.selectDictLabel(state.statusOptions, row.status);
};

// 操作日志类型字典翻译
const typeFormat = (row: any, column: any) => {
  return proxy.selectDictLabel(state.typeOptions, row.businessType);
};
// 多选框选中数据
const handleSelectionChange = (selection: any) => {
  state.ids = selection.map((item: any) => item.operId);
  state.single = selection.length != 1;
  state.multiple = !selection.length;
};

// 页面加载时调用
onMounted(() => {
  //   proxy.mittBus.on("onEditPostModule", (res: any) => {
  //     handleQuery();
  //   });
  // 查询列表数据信息
  handleQuery();
  proxy.getDicts("sys_common_status").then((response: any) => {
    state.statusOptions = response.data;
  });
  proxy.getDicts("sys_oper_type").then((response: any) => {
    state.typeOptions = response.data;
  });
});
</script>

<style>
.oper-detail-dialog {
  max-width: 94vw;
}
.oper-detail-dialog :deep(.el-dialog__body) {
  max-height: 70vh;
  overflow-y: auto;
  padding: 12px 20px 4px;
}
.oper-detail-dialog :deep(.el-descriptions__body) {
  background: #fff;
}
.oper-desc :deep(.el-descriptions__label) {
  width: 92px;
  color: #606266;
}
.oper-method {
  display: inline-block;
  min-width: 56px;
  font-family: Consolas, monospace;
  font-size: 12px;
  font-weight: 600;
  color: #409eff;
}
.oper-url {
  font-family: Consolas, monospace;
  font-size: 12px;
  word-break: break-all;
}
.oper-error {
  color: #f56c6c;
}

/* 执行链路面板 */
.flow-panel {
  margin-top: 18px;
  border: 1px solid #ebeef5;
  border-radius: 6px;
  overflow: hidden;
}
.flow-panel__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
  background: #fafbfc;
  border-bottom: 1px solid #ebeef5;
}
.flow-panel__title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  font-weight: 600;
  color: #303133;
}
.flow-panel__mark {
  width: 3px;
  height: 14px;
  border-radius: 2px;
  background: #409eff;
}
.flow-panel__metrics {
  display: flex;
  align-items: center;
  gap: 14px;
  font-size: 12px;
  color: #909399;
}
.flow-panel__metrics em {
  font-style: normal;
  font-weight: 600;
  color: #303133;
}
.flow-panel__metrics .is-ok em {
  color: #67c23a;
}
.flow-panel__metrics .is-fail em {
  color: #f56c6c;
}
.flow-panel__metrics .is-skip em {
  color: #909399;
}
.flow-panel__hint {
  font-size: 12px;
  color: #c0c4cc;
}

/* 步骤时间轴 */
.flow-steps {
  padding: 14px 18px 4px;
}
.flow-step {
  display: flex;
  gap: 12px;
}
.flow-step__rail {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 22px;
  flex: 0 0 22px;
}
.flow-step__dot {
  width: 22px;
  height: 22px;
  line-height: 22px;
  text-align: center;
  border-radius: 50%;
  font-size: 12px;
  font-weight: 600;
  color: #fff;
  background: #67c23a;
}
.flow-step.is-fail .flow-step__dot {
  background: #f56c6c;
}
.flow-step.is-skip .flow-step__dot {
  background: #c0c4cc;
}
.flow-step__line {
  flex: 1;
  width: 2px;
  min-height: 16px;
  margin: 4px 0;
  background: #dcdfe6;
}
.flow-step__body {
  flex: 1;
  min-width: 0;
  padding-bottom: 16px;
}
.flow-step__title {
  display: flex;
  align-items: center;
  gap: 8px;
  min-height: 22px;
}
.flow-step__name {
  font-size: 14px;
  font-weight: 600;
  color: #303133;
}
.flow-step__cost {
  font-size: 12px;
  color: #909399;
}
.flow-step__fields {
  margin-top: 8px;
  padding: 8px 12px;
  background: #f7f8fa;
  border-radius: 4px;
}
.flow-field {
  display: flex;
  gap: 10px;
  font-size: 12px;
  line-height: 20px;
}
.flow-field + .flow-field {
  margin-top: 2px;
}
.flow-field__label {
  flex: 0 0 60px;
  color: #909399;
}
.flow-field__value {
  flex: 1;
  min-width: 0;
  color: #303133;
  font-family: Consolas, "Courier New", monospace;
  word-break: break-all;
  white-space: pre-wrap;
}

/* ASCII 原文 */
.flow-raw {
  border-top: 1px solid #ebeef5;
}
.flow-raw :deep(.el-collapse-item__header) {
  padding-left: 16px;
  font-size: 13px;
  color: #606266;
}
.flow-raw :deep(.el-collapse-item__content) {
  padding: 0 16px 14px;
}
.flow-raw__actions {
  display: flex;
  justify-content: flex-end;
  margin-bottom: 4px;
}
.flow-chart {
  margin: 0;
  padding: 10px 12px;
  width: 100%;
  max-height: 360px;
  overflow: auto;
  font-family: "Sarasa Mono SC", "Microsoft YaHei Mono", NSimSun, monospace;
  font-size: 12px;
  line-height: 1.45;
  white-space: pre;
  background: #1e1e1e;
  color: #d4d4d4;
  border-radius: 4px;
}
</style>
