<template>
  <div 
    class="canvas" 
    ref="canvasRef"
    @wheel="$event => handleMousewheelCanvas($event)"
    @contextmenu.prevent
  >
    <div 
      class="viewport-wrapper"
      :style="{
        width: viewportStyles.width * canvasScale + 'px',
        height: viewportStyles.height * canvasScale + 'px',
        left: viewportStyles.left + 'px',
        top: viewportStyles.top + 'px',
      }"
    >
      <div class="operates">
        <ViewportBackground />
      </div>

      <div 
        class="viewport" 
        ref="viewportRef"
        :style="{ 
          transform: `scale(${canvasScale})`,
          width: viewportStyles.width + 'px',
          height: viewportStyles.height + 'px',
        }"
      >
        <EditableElement 
          v-for="(element, index) in elementList" 
          :key="element.id"
          :elementInfo="element"
          :elementIndex="index + 1"
          :isMultiSelect="false"
          :selectElement="() => {}"
          :openLinkDialog="() => {}"
          v-show="!hiddenElementIdList.includes(element.id)"
        />
      </div>
    </div>

  </div>
</template>

<script lang="ts" setup>
import { nextTick, onMounted, provide, ref, watchEffect, useTemplateRef } from 'vue'
import { throttle } from 'lodash'
import { storeToRefs } from 'pinia'
import { useMainStore, useSlidesStore, useKeyboardStore } from '@/store'
import type { PPTElement } from '@/types/slides'
import { injectKeySlideScale } from '@/types/injectKey'
import { removeAllRanges } from '@/utils/selection'
import { KEYS } from '@/configs/hotkey'

import useViewportSize from './hooks/useViewportSize'
import useScaleCanvas from '@/hooks/useScaleCanvas'
import useSlideHandler from '@/hooks/useSlideHandler'

import EditableElement from './EditableElement.vue'
import ViewportBackground from './ViewportBackground.vue'

const mainStore = useMainStore()
const {
  activeElementIdList,
  hiddenElementIdList,
  canvasScale,
} = storeToRefs(mainStore)
const { currentSlide } = storeToRefs(useSlidesStore())
const { ctrlKeyState } = storeToRefs(useKeyboardStore())

const viewportRef = useTemplateRef<HTMLElement>('viewportRef')

const elementList = ref<PPTElement[]>([])
const setLocalElementList = () => {
  elementList.value = currentSlide.value ? JSON.parse(JSON.stringify(currentSlide.value.elements)) : []
}
watchEffect(setLocalElementList)

const canvasRef = useTemplateRef<HTMLElement>('canvasRef')
const { viewportStyles } = useViewportSize(canvasRef)

// 只读模式：禁用所有编辑相关的 hooks
const selectElement = () => {}

const { updateSlideIndex } = useSlideHandler()

// 组件渲染时，如果存在元素焦点，需要清除
// 这种情况存在于：有焦点元素的情况下进入了放映模式，再退出时，需要清除原先的焦点（因为可能已经切换了页面）
onMounted(() => {
  if (activeElementIdList.value.length) {
    nextTick(() => mainStore.setActiveElementIdList([]))
  }
})

// 点击画布的空白区域：清空焦点元素、设置画布焦点、清除文字选区、清空格式刷状态
const handleClickBlankArea = (e: MouseEvent) => {
  // 只读模式：禁用所有编辑功能
  if (activeElementIdList.value.length) mainStore.setActiveElementIdList([])
  removeAllRanges()
}

// 双击空白处插入文本 - 只读模式禁用
const handleDblClick = () => {
  // 只读模式：禁用创建元素
}


// 滚动鼠标
const { scaleCanvas } = useScaleCanvas()
const throttleScaleCanvas = throttle(scaleCanvas, 100, { leading: true, trailing: false })
const throttleUpdateSlideIndex = throttle(updateSlideIndex, 300, { leading: true, trailing: false })

const handleMousewheelCanvas = (e: WheelEvent) => {
  e.preventDefault()

  // 按住Ctrl键时：缩放画布
  if (ctrlKeyState.value) {
    if (e.deltaY > 0) throttleScaleCanvas('-')
    else if (e.deltaY < 0) throttleScaleCanvas('+')
  }
  // 上下翻页
  else {
    if (e.deltaY > 0) throttleUpdateSlideIndex(KEYS.DOWN)
    else if (e.deltaY < 0) throttleUpdateSlideIndex(KEYS.UP)
  }
}

provide(injectKeySlideScale, canvasScale)
</script>

<style lang="scss" scoped>
.canvas {
  height: 100%;
  user-select: none;
  overflow: hidden;
  background-color: $lightGray;
  position: relative;
}
.viewport-wrapper {
  position: absolute;
  box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.01), 0 0 12px 0 rgba(0, 0, 0, 0.1);
}
.viewport {
  position: absolute;
  top: 0;
  left: 0;
  transform-origin: 0 0;
  
  // 只读模式：禁用元素的拖拽和选择，但保持显示
  :deep(.editable-element) {
    cursor: default !important;
    
    // 禁用文本选择
    * {
      user-select: none !important;
      -webkit-user-select: none !important;
      -moz-user-select: none !important;
      -ms-user-select: none !important;
    }
    
    // 但允许视频播放等必要的交互
    video,
    audio {
      pointer-events: auto;
      cursor: pointer;
    }
  }
}
</style>