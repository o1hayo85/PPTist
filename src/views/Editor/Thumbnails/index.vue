<template>
  <div 
    class="thumbnails"
  >
    <div class="thumbnail-list"
      ref="thumbnailsRef"
    >
      <div 
        v-for="(element, index) in slides"
        :key="element.id"
        class="thumbnail-container"
      >
        <div class="section-title"
          :data-section-id="element?.sectionTag?.id || ''"
          v-if="element.sectionTag || (hasSection && index === 0)"
        >
          <span class="text">
            <div class="text-content">{{ element?.sectionTag ? (element?.sectionTag?.title || '无标题节') : '默认节' }}</div>
          </span>
        </div>
        <div
          class="thumbnail-item"
          :class="{
            'active': slideIndex === index,
          }"
          @click="() => handleClickSlideThumbnail(index)"
          @dblclick="enterScreening()"
        >
          <div class="label" :class="{ 'offset-left': index >= 99 }">{{ fillDigit(index + 1, 2) }}</div>
          <ThumbnailSlide class="thumbnail" :slide="element" :size="120" :visible="index < slidesLoadLimit" />
        </div>
      </div>
    </div>

    <div class="page-number">幻灯片 {{slideIndex + 1}} / {{slides.length}}</div>
  </div>
</template>

<script lang="ts" setup>
import { computed, nextTick, ref, watch, useTemplateRef } from 'vue'
import { storeToRefs } from 'pinia'
import { useMainStore, useSlidesStore } from '@/store'
import { fillDigit } from '@/utils/common'
import { isElementInViewport } from '@/utils/element'
import useScreening from '@/hooks/useScreening'
import useLoadSlides from '@/hooks/useLoadSlides'

import ThumbnailSlide from '@/views/components/ThumbnailSlide/index.vue'

const mainStore = useMainStore()
const slidesStore = useSlidesStore()
const { slides, slideIndex } = storeToRefs(slidesStore)

const { slidesLoadLimit } = useLoadSlides()

const hasSection = computed(() => {
  return slides.value.some(item => item.sectionTag)
})

const thumbnailsRef = useTemplateRef<HTMLElement>('thumbnailsRef')

// 页面被切换时
watch(() => slideIndex.value, () => {
  // 检查当前页缩略图是否在可视范围，不在的话需要滚动到对应的位置
  nextTick(() => {
    const activeThumbnailRef: HTMLElement = thumbnailsRef.value?.querySelector('.thumbnail-item.active') as HTMLElement
    if (thumbnailsRef.value && activeThumbnailRef && !isElementInViewport(activeThumbnailRef, thumbnailsRef.value)) {
      setTimeout(() => {
        activeThumbnailRef.scrollIntoView({ behavior: 'smooth' })
      }, 100)
    }
  })
}, { immediate: true })

// 切换页面
const changeSlideIndex = (index: number) => {
  mainStore.setActiveElementIdList([])

  if (slideIndex.value === index) return
  slidesStore.updateSlideIndex(index)
}

// 点击缩略图
const handleClickSlideThumbnail = (index: number) => {
  changeSlideIndex(index)
}

const { enterScreening } = useScreening()
</script>

<style lang="scss" scoped>
.thumbnails {
  border-right: solid 1px $borderColor;
  background-color: #fff;
  display: flex;
  flex-direction: column;
  user-select: none;
}
.thumbnail-list {
  padding: 5px 0;
  flex: 1;
  overflow: auto;
  display: flex;
  flex-direction: column;
}
.thumbnail-item {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 5px 0;
  position: relative;

  .thumbnail {
    border-radius: $borderRadius;
    outline: 2px solid rgba($color: $themeColor, $alpha: .15);
  }

  &.active {
    .label {
      color: $themeColor;
    }
    .thumbnail {
      outline-color: $themeColor;
    }
  }
}
.label {
  font-size: 12px;
  color: #999;
  width: 20px;

  &.offset-left {
    position: relative;
    left: -4px;
  }
}
.page-number {
  height: 40px;
  font-size: 12px;
  border-top: 1px solid $borderColor;
  line-height: 40px;
  text-align: center;
  color: #666;
}
.section-title {
  height: 26px;
  font-size: 12px;
  padding: 6px 8px 2px 18px;
  color: #555;

  &.contextmenu-active {
    color: $themeColor;

    .text::before {
      border-bottom-color: $themeColor;
      border-right-color: $themeColor;
    }
  }

  .text {
    display: flex;
    align-items: center;
    position: relative;

    &::before {
      content: '';
      width: 0;
      height: 0;
      border-top: 3px solid transparent;
      border-left: 3px solid transparent;
      border-bottom: 3px solid #555;
      border-right: 3px solid #555;
      margin-right: 5px;
    }

    .text-content {
      display: inline-block;
      @include ellipsis-oneline();
    }
  }

  input {
    width: 100%;
    border: 0;
    outline: 0;
    padding: 0;
    font-size: 12px;
  }
}
</style>