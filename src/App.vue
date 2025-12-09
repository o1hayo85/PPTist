<template>
  <template v-if="slides.length">
    <Screen v-if="screening" />
    <Editor v-else-if="_isPC" />
    <Mobile v-else />
  </template>
  <FullscreenSpin tip="数据初始化中，请稍等 ..." v-else :loading="loading && !errorMessage" :mask="false" />
  
  <Modal
    :visible="!!errorMessage"
    :width="420"
    :closeButton="false"
    :closeOnClickMask="false"
    :closeOnEsc="false"
    :contentStyle="{ borderRadius: '10px', boxShadow: '0 20px 60px rgba(0, 0, 0, 0.3)' }"
  >
    <div class="error-dialog">
      <div class="error-icon">
        <IconAttention theme="filled" :size="48" fill="#ff4d4f" />
      </div>
      <div class="error-title">文件加载失败</div>
      <div class="error-message">{{ errorMessage }}</div>
    </div>
  </Modal>
</template>



<script lang="ts" setup>
import { onMounted, ref, watch } from 'vue'
import { storeToRefs } from 'pinia'
import { useScreenStore, useMainStore, useSnapshotStore, useSlidesStore } from '@/store'
import { LOCALSTORAGE_KEY_DISCARDED_DB } from '@/configs/storage'
import { deleteDiscardedDB } from '@/utils/database'
import { isPC } from '@/utils/common'
import api from '@/services'
import useImport from '@/hooks/useImport'

import Editor from './views/Editor/index.vue'
import Screen from './views/Screen/index.vue'
import Mobile from './views/Mobile/index.vue'
import FullscreenSpin from '@/components/FullscreenSpin.vue'
import Modal from '@/components/Modal.vue'

const _isPC = isPC()

const mainStore = useMainStore()
const slidesStore = useSlidesStore()
const snapshotStore = useSnapshotStore()
const { databaseId } = storeToRefs(mainStore)
const { slides } = storeToRefs(slidesStore)
const { screening } = storeToRefs(useScreenStore())

const { importPPTXFile, exporting } = useImport()
const loading = ref(true)
const errorMessage = ref('')

// if (import.meta.env.MODE === 'development') {
//   window.onbeforeunload = () => false
// }
// window.onbeforeunload = () => false

// 从 URL 参数中获取 PPT 文件地址并在线导入
const loadPPTFromURL = async () => {
  const urlParams = new URLSearchParams(window.location.search)
  const pptUrl = urlParams.get('url') || urlParams.get('ppt') || urlParams.get('file')
  
  if (pptUrl) {
    try {
      loading.value = true
      // 下载文件
      const response = await fetch(pptUrl)
      if (!response.ok) {
        throw new Error('下载文件失败')
      }
      const blob = await response.blob()
      
      // 将 Blob 转换为 File 对象
      const fileName = pptUrl.split('/').pop() || 'presentation.pptx'
      const file = new File([blob], fileName, { type: 'application/vnd.openxmlformats-officedocument.presentationml.presentation' })
      
      // 导入 PPTX 文件
      importPPTXFile([file], { cover: true, fixedViewport: false })
      
      // 监听 exporting 状态变化来判断导入是否完成
      const unwatch = watch(exporting, (isExporting) => {
        if (!isExporting) {
          // 导入完成，检查是否有幻灯片
          loading.value = false
          unwatch() // 停止监听
          
          // 如果导入失败，useImport 内部会显示 message.error
          // 但我们还需要在弹窗中显示错误
          setTimeout(() => {
            if (slides.value.length === 0) {
              errorMessage.value = `错误：无法正确读取 / 解析该文件\n文件地址：${pptUrl}\n请检查文件格式是否正确`
            }
          }, 100)
        }
      }, { immediate: true })
    }
    catch (error) {
      // eslint-disable-next-line no-console
      console.error('加载 PPT 文件失败:', error)
      loading.value = false
      // 显示错误信息
      const errorMsg = error instanceof Error ? error.message : '加载 PPT 文件失败，请检查 URL 是否正确'
      errorMessage.value = `错误：${errorMsg}\n\n文件地址：${pptUrl}`
    }
  }
  else {
    // 如果没有 URL 参数，使用默认数据
    try {
      const defaultSlides = await api.getMockData('slides')
      slidesStore.setSlides(defaultSlides)
      loading.value = false
    }
    catch (error) {
      loading.value = false
      const errorMsg = error instanceof Error ? error.message : '加载默认数据失败'
      errorMessage.value = `错误：${errorMsg}`
    }
  }
}

onMounted(async () => {
  await deleteDiscardedDB()
  snapshotStore.initSnapshotDatabase()
  await loadPPTFromURL()
})

// 应用注销时向 localStorage 中记录下本次 indexedDB 的数据库ID，用于之后清除数据库
window.addEventListener('beforeunload', () => {
  const discardedDB = localStorage.getItem(LOCALSTORAGE_KEY_DISCARDED_DB)
  const discardedDBList: string[] = discardedDB ? JSON.parse(discardedDB) : []

  discardedDBList.push(databaseId.value)

  const newDiscardedDB = JSON.stringify(discardedDBList)
  localStorage.setItem(LOCALSTORAGE_KEY_DISCARDED_DB, newDiscardedDB)
})
</script>

<style lang="scss">
#app {
  height: 100%;
}

.error-dialog {
  padding: 24px 20px;
  text-align: center;
  
  .error-icon {
    margin-bottom: 16px;
    display: flex;
    justify-content: center;
    animation: shake 0.5s ease-in-out;
  }
  
  .error-title {
    font-size: 18px;
    font-weight: 600;
    color: #333;
    margin-bottom: 12px;
    letter-spacing: 0.3px;
  }
  
  .error-message {
    font-size: 13px;
    color: #555;
    line-height: 1.6;
    white-space: pre-wrap;
    word-break: break-all;
    text-align: left;
    background: linear-gradient(135deg, #f8f9fa 0%, #f1f3f5 100%);
    border: 1px solid #e9ecef;
    padding: 14px;
    border-radius: 6px;
    max-height: 280px;
    overflow-y: auto;
    box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.06);
    position: relative;
    
    &::-webkit-scrollbar {
      width: 5px;
    }
    
    &::-webkit-scrollbar-track {
      background: #f1f1f1;
      border-radius: 3px;
    }
    
    &::-webkit-scrollbar-thumb {
      background: #c1c1c1;
      border-radius: 3px;
      
      &:hover {
        background: #a8a8a8;
      }
    }
    
    &::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      height: 2px;
      background: linear-gradient(90deg, #ff4d4f, #ff7875, #ff4d4f);
      border-radius: 6px 6px 0 0;
    }
  }
}

@keyframes shake {
  0%, 100% {
    transform: translateX(0);
  }
  10%, 30%, 50%, 70%, 90% {
    transform: translateX(-5px);
  }
  20%, 40%, 60%, 80% {
    transform: translateX(5px);
  }
}
</style>