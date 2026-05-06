// Global configuration for tree-shaking levels in the talk demo.

const int imageTreeShakingNone = 0;
const int imageTreeShakingFilterOnly = 1;
const int imageTreeShakingFilterAndResize = 2;

// const bool enableAudioTreeShaking = false;
// const int imageTreeShakingLevel = imageTreeShakingNone;
// const bool enableTranslationTreeShaking = false;
// const bool translationTreeShakingLookAtUserDefines = false;
// const bool enableNativeTreeShaking = false;

const bool enableAudioTreeShaking = true;
const int imageTreeShakingLevel = imageTreeShakingFilterAndResize;
const bool enableTranslationTreeShaking = true;
const bool translationTreeShakingLookAtUserDefines = true;
const bool enableNativeTreeShaking = true;
