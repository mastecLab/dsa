function initTestJs(){
     var count = 0;
     function onInvoke(meta, getValue, setValue){
          setValue('a', 'hello world ' + count++);
     }
     return onInvoke;
}