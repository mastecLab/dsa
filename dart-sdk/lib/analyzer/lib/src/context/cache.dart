// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.context.cache;

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/src/dart/element/element.dart'
    show ElementImpl, Modifier;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/task/model.dart';
import 'package:analyzer/task/model.dart';

/**
 * Return `true` if the given [target] is a priority one.
 */
typedef bool IsPriorityAnalysisTarget(AnalysisTarget target);

/**
 * An LRU cache of results produced by analysis.
 */
class AnalysisCache {
  /**
   * A flag used to control whether trace information should be produced when
   * the content of the cache is modified.
   */
  static bool _TRACE_CHANGES = false;

  /**
   * An array containing the partitions of which this cache is comprised.
   */
  final List<CachePartition> _partitions;

  /**
   * The [StreamController] reporting [InvalidatedResult]s.
   */
  final ReentrantSynchronousStream<InvalidatedResult> onResultInvalidated =
      new ReentrantSynchronousStream<InvalidatedResult>();

  final List<ReentrantSynchronousStreamSubscription>
      onResultInvalidatedPartitionSubscriptions =
      <ReentrantSynchronousStreamSubscription>[];

  /**
   * Initialize a newly created cache to have the given [_partitions]. The
   * partitions will be searched in the order in which they appear in the array,
   * so the most specific partition (usually an [SdkCachePartition]) should be
   * first and the most general (usually a [UniversalCachePartition]) last.
   */
  AnalysisCache(this._partitions) {
    for (CachePartition partition in _partitions) {
      ReentrantSynchronousStreamSubscription<InvalidatedResult> subscription =
          partition.onResultInvalidated.listen((InvalidatedResult event) {
        onResultInvalidated.add(event);
      });
      onResultInvalidatedPartitionSubscriptions.add(subscription);
    }
  }

  /**
   * Return an iterator returning all of the [Source] targets.
   */
  Iterable<Source> get sources {
    return _partitions
        .map((CachePartition partition) => partition.sources)
        .expand((Iterable<Source> sources) => sources);
  }

  // TODO(brianwilkerson) Implement or delete this.
//  /**
//   * Return information about each of the partitions in this cache.
//   */
//  List<AnalysisContextStatistics_PartitionData> get partitionData {
//    int count = _partitions.length;
//    List<AnalysisContextStatistics_PartitionData> data =
//        new List<AnalysisContextStatistics_PartitionData>(count);
//    for (int i = 0; i < count; i++) {
//      CachePartition partition = _partitions[i];
//      data[i] = new AnalysisContextStatisticsImpl_PartitionDataImpl(
//          partition.astSize,
//          partition.map.length);
//    }
//    return data;
//  }

  /**
   * Free any allocated resources and references.
   */
  void dispose() {
    for (ReentrantSynchronousStreamSubscription subscription
        in onResultInvalidatedPartitionSubscriptions) {
      subscription.cancel();
    }
  }

  /**
   * Return the entry associated with the given [target].
   */
  CacheEntry get(AnalysisTarget target) {
    int count = _partitions.length;
    for (int i = 0; i < count; i++) {
      CachePartition partition = _partitions[i];
      if (partition.isResponsibleFor(target)) {
        return partition.get(target);
      }
    }
    //
    // We should never get to this point because the last partition should
    // always be a universal partition, except in the case of the SDK context,
    // in which case the target should always be part of the SDK.
    //
    return null;
  }

  /**
   * Return the context to which the given [target] was explicitly added.
   */
  InternalAnalysisContext getContextFor(AnalysisTarget target) {
    int count = _partitions.length;
    for (int i = 0; i < count; i++) {
      CachePartition partition = _partitions[i];
      if (partition.isResponsibleFor(target)) {
        return partition.context;
      }
    }
    //
    // We should never get to this point because the last partition should
    // always be a universal partition, except in the case of the SDK context,
    // in which case the target should always be part of the SDK.
    //
    // TODO(brianwilkerson) Throw an exception here.
    AnalysisEngine.instance.logger.logInformation(
        'Could not find context for $target',
        new CaughtException(new AnalysisException(), null));
    return null;
  }

  /**
   * Return [Source]s whose full path is equal to the given [path].
   * Maybe empty, but not `null`.
   */
  List<Source> getSourcesWithFullName(String path) {
    List<Source> sources = <Source>[];
    for (CachePartition partition in _partitions) {
      List<Source> partitionSources = partition.getSourcesWithFullName(path);
      sources.addAll(partitionSources);
    }
    return sources;
  }

  /**
   * Return the state of the given [result] for the given [target].
   *
   * It does not update the cache, if the corresponding [CacheEntry] does not
   * exist, then [CacheState.INVALID] is returned.
   */
  CacheState getState(AnalysisTarget target, ResultDescriptor result) {
    CacheEntry entry = get(target);
    if (entry == null) {
      return CacheState.INVALID;
    }
    return entry.getState(result);
  }

  /**
   * Return the value of the given [result] for the given [target].
   *
   * It does not update the cache, if the corresponding [CacheEntry] does not
   * exist, then the default value is returned.
   */
  Object getValue(AnalysisTarget target, ResultDescriptor result) {
    CacheEntry entry = get(target);
    if (entry == null) {
      return result.defaultValue;
    }
    return entry.getValue(result);
  }

  /**
   * Return an iterator returning all of the map entries mapping targets to
   * cache entries. If the [context] is not `null`, then only entries that are
   * owned by the given context will be returned.
   */
  MapIterator<AnalysisTarget, CacheEntry> iterator(
      {InternalAnalysisContext context: null}) {
    List<Map<AnalysisTarget, CacheEntry>> maps =
        <Map<AnalysisTarget, CacheEntry>>[];
    for (CachePartition partition in _partitions) {
      if (context == null || partition.context == context) {
        maps.add(partition.entryMap);
      }
    }
    return new MultipleMapIterator<AnalysisTarget, CacheEntry>(maps);
  }

  /**
   * Puts the given [entry] into the cache.
   */
  void put(CacheEntry entry) {
    AnalysisTarget target = entry.target;
    entry.fixExceptionState();
    int count = _partitions.length;
    for (int i = 0; i < count; i++) {
      CachePartition partition = _partitions[i];
      if (partition.isResponsibleFor(target)) {
        if (_TRACE_CHANGES) {
          CacheEntry oldEntry = partition.get(target);
          if (oldEntry == null) {
            AnalysisEngine.instance.logger
                .logInformation('Added a cache entry for $target.');
          } else {
            AnalysisEngine.instance.logger
                .logInformation('Modified the cache entry for $target.');
//                'Diff = ${entry.getDiff(oldEntry)}');
          }
        }
        partition.put(entry);
        return;
      }
    }
    // TODO(brianwilkerson) Handle the case where no partition was found,
    // possibly by throwing an exception.
  }

  /**
   * Remove all information related to the given [target] from this cache.
   * Return the entry associated with the target, or `null` if there was cache
   * entry for the target.
   */
  CacheEntry remove(AnalysisTarget target) {
    int count = _partitions.length;
    for (int i = 0; i < count; i++) {
      CachePartition partition = _partitions[i];
      if (partition.isResponsibleFor(target)) {
        if (_TRACE_CHANGES) {
          AnalysisEngine.instance.logger
              .logInformation('Removed the cache entry for $target.');
        }
        CacheEntry entry = partition.remove(target);
        if (entry != null) {
          entry.dispose();
        }
        return entry;
      }
    }
    return null;
  }

  /**
   * Return the number of targets that are mapped to cache entries.
   */
  int size() {
    int size = 0;
    int count = _partitions.length;
    for (int i = 0; i < count; i++) {
      size += _partitions[i].size();
    }
    return size;
  }
}

/**
 * The information cached by an analysis context about an individual target.
 */
class CacheEntry {
  /**
   * The index of the flag indicating whether the source was explicitly added to
   * the context or whether the source was implicitly added because it was
   * referenced by another source.
   */
  static int _EXPLICITLY_ADDED_FLAG = 0;

  /**
   * The next invalidation process identifier.
   */
  static int nextInvalidateId = 0;

  /**
   * The target this entry is about.
   */
  final AnalysisTarget target;

  /**
   * The partition that is responsible for this entry.
   */
  CachePartition _partition;

  /**
   * The most recent time at which the state of the target matched the state
   * represented by this entry, `-1` if the target does not exist.
   */
  int modificationTime = -1;

  /**
   * The exception that caused one or more values to have a state of
   * [CacheState.ERROR].
   */
  CaughtException _exception;

  /**
   * A bit-encoding of boolean flags associated with this entry's target.
   */
  int _flags = 0;

  /**
   * A table mapping result descriptors to the cached values of those results.
   */
  Map<ResultDescriptor, ResultData> _resultMap =
      new HashMap<ResultDescriptor, ResultData>();

  CacheEntry(this.target) {
    if (target is ElementImpl) {
      (target as ElementImpl).setModifier(Modifier.CACHE_KEY, true);
    }
  }

  /**
   * The exception that caused one or more values to have a state of
   * [CacheState.ERROR].
   */
  CaughtException get exception => _exception;

  /**
   * Return `true` if the source was explicitly added to the context or `false`
   * if the source was implicitly added because it was referenced by another
   * source.
   */
  bool get explicitlyAdded => _getFlag(_EXPLICITLY_ADDED_FLAG);

  /**
   * Set whether the source was explicitly added to the context to match the
   * [explicitlyAdded] flag.
   */
  void set explicitlyAdded(bool explicitlyAdded) {
    _setFlag(_EXPLICITLY_ADDED_FLAG, explicitlyAdded);
  }

  /**
   * Return a list of result descriptors for results whose state is not
   * [CacheState.INVALID].
   */
  List<ResultDescriptor> get nonInvalidResults => _resultMap.keys.toList();

  /**
   * Notifies the entry that the client is going to stop using it.
   */
  void dispose() {
    _resultMap.forEach((descriptor, data) {
      TargetedResult result = new TargetedResult(target, descriptor);
      for (TargetedResult dependedOnResult in data.dependedOnResults) {
        ResultData dependedOnData = _partition._getDataFor(dependedOnResult);
        if (dependedOnData != null) {
          dependedOnData.dependentResults.remove(result);
        }
      }
    });
    _resultMap.clear();
    if (target is ElementImpl) {
      (target as ElementImpl).setModifier(Modifier.CACHE_KEY, false);
    }
  }

  /**
   * Fix the state of the [exception] to match the current state of the entry.
   */
  void fixExceptionState() {
    if (!hasErrorState()) {
      _exception = null;
    }
  }

  /**
   * Look up the [ResultData] of [descriptor], or add a new one if it isn't
   * there.
   */
  ResultData getResultData(ResultDescriptor descriptor) {
    return _resultMap.putIfAbsent(descriptor, () => new ResultData(descriptor));
  }

  /**
   * Return the state of the result represented by the given [descriptor].
   */
  CacheState getState(ResultDescriptor descriptor) {
    ResultData data = _resultMap[descriptor];
    if (data == null) {
      return CacheState.INVALID;
    }
    return data.state;
  }

  /**
   * Return the value of the result represented by the given [descriptor], or
   * the default value for the result if this entry does not have a valid value.
   */
  dynamic/*=V*/ getValue/*<V>*/(ResultDescriptor/*<V>*/ descriptor) {
    ResultData data = _resultMap[descriptor];
    if (data == null) {
      return descriptor.defaultValue;
    }
    if (_partition != null) {
      _partition.resultAccessed(target, descriptor);
    }
    return data.value;
  }

  /**
   * Return `true` if the state of any data value is [CacheState.ERROR].
   */
  bool hasErrorState() {
    for (ResultData data in _resultMap.values) {
      if (data.state == CacheState.ERROR) {
        return true;
      }
    }
    return false;
  }

  /**
   * Invalidate all of the information associated with this entry's target.
   */
  void invalidateAllInformation() {
    _resultMap.clear();
    _exception = null;
  }

  /**
   * Return `true` if the state of the result represented by the given
   * [descriptor] is [CacheState.INVALID].
   */
  bool isInvalid(ResultDescriptor descriptor) =>
      getState(descriptor) == CacheState.INVALID;

  /**
   * Return `true` if the state of the result represented by the given
   * [descriptor] is [CacheState.VALID].
   */
  bool isValid(ResultDescriptor descriptor) =>
      getState(descriptor) == CacheState.VALID;

  /**
   * For each of the given [descriptors], set their states to
   * [CacheState.ERROR], their values to the corresponding default values, and
   * remember the [exception] that caused this state.
   */
  void setErrorState(
      CaughtException exception, List<ResultDescriptor> descriptors) {
    if (descriptors == null || descriptors.isEmpty) {
      throw new ArgumentError('at least one descriptor is expected');
    }
    if (exception == null) {
      throw new ArgumentError('an exception is expected');
    }
    this._exception = exception;
    for (ResultDescriptor descriptor in descriptors) {
      _setErrorState(descriptor, exception);
    }
  }

  /**
   * Set the state of the result represented by the given [descriptor] to the
   * given [state].
   */
  void setState(ResultDescriptor descriptor, CacheState state, {Delta delta}) {
    if (state == CacheState.ERROR) {
      throw new ArgumentError('use setErrorState() to set the state to ERROR');
    }
    if (state == CacheState.VALID) {
      throw new ArgumentError('use setValue() to set the state to VALID');
    }
    _validateStateChange(descriptor, state);
    if (state == CacheState.INVALID) {
      ResultData data = _resultMap[descriptor];
      if (data != null) {
        _invalidate(nextInvalidateId++, descriptor, delta, 0);
      }
    } else {
      ResultData data = getResultData(descriptor);
      data.state = state;
      if (state != CacheState.IN_PROCESS) {
        //
        // If the state is in-process, we can leave the current value in the
        // cache for any 'get' methods to access.
        //
        data.value = descriptor.defaultValue;
      }
    }
  }

  /**
   * Set the value of the result represented by the given [descriptor] to the
   * given [value].
   */
  void setValue/*<V>*/(ResultDescriptor/*<V>*/ descriptor, dynamic/*=V*/ value,
      List<TargetedResult> dependedOn) {
//    {
//      String valueStr = '$value';
//      if (valueStr.length > 20) {
//        valueStr = valueStr.substring(0, 20) + '...';
//      }
//      valueStr = valueStr.replaceAll('\n', '\\n');
//      print(
//          'setValue $descriptor for $target value=$valueStr $dependedOn=$dependedOn');
//    }
    _validateStateChange(descriptor, CacheState.VALID);
    TargetedResult thisResult = new TargetedResult(target, descriptor);
    if (_partition != null) {
      _partition.resultStored(thisResult, value);
    }
    ResultData data = getResultData(descriptor);
    _setDependedOnResults(data, thisResult, dependedOn);
    data.state = CacheState.VALID;
    data.value = value == null ? descriptor.defaultValue : value;
  }

  /**
   * If the result represented by the given [descriptor] is valid, set
   * it to the given [value], keep its dependency, and if [invalidateDependent]
   * invalidate all the dependent result.
   */
  void setValueIncremental(
      ResultDescriptor descriptor, dynamic value, bool invalidateDependent) {
    ResultData data = getResultData(descriptor);
    if (data.state == CacheState.VALID || data.state == CacheState.FLUSHED) {
      data.value = value;
    }
    if (invalidateDependent) {
      _invalidateDependentResults(nextInvalidateId++, data, null, 0);
    }
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    _writeOn(buffer);
    return buffer.toString();
  }

  /**
   * Return the value of the flag with the given [index].
   */
  bool _getFlag(int index) => BooleanArray.get(_flags, index);

  /**
   * Invalidate the result represented by the given [descriptor] and propagate
   * invalidation to other results that depend on it.
   */
  void _invalidate(
      int id, ResultDescriptor descriptor, Delta delta, int level) {
    ResultData thisData = _resultMap[descriptor];
    if (thisData == null) {
      return;
    }
    // Stop if already validated.
    if (delta != null) {
      if (thisData.invalidateId == id) {
        return;
      }
      thisData.invalidateId = id;
    }
    // Ask the delta to validate.
    DeltaResult deltaResult = null;
    if (delta != null) {
      deltaResult = delta.validate(_partition.context, target, descriptor);
      if (deltaResult == DeltaResult.STOP) {
        return;
      }
    }
    if (deltaResult == DeltaResult.INVALIDATE_NO_DELTA) {
      delta = null;
    }
    if (deltaResult == null ||
        deltaResult == DeltaResult.INVALIDATE ||
        deltaResult == DeltaResult.INVALIDATE_NO_DELTA) {
      _resultMap.remove(descriptor);
//      {
//        String indent = '  ' * level;
//        print('[$id]$indent invalidate $descriptor for $target');
//      }
    }
    // Stop depending on other results.
    TargetedResult thisResult = new TargetedResult(target, descriptor);
    for (TargetedResult dependedOnResult in thisData.dependedOnResults) {
      ResultData data = _partition._getDataFor(dependedOnResult);
      if (data != null && deltaResult != DeltaResult.KEEP_CONTINUE) {
        data.dependentResults.remove(thisResult);
      }
    }
    // Invalidate results that depend on this result.
    _invalidateDependentResults(id, thisData, delta, level + 1);
    // If empty and not explicitly added, remove the entry altogether.
    if (_resultMap.isEmpty && !explicitlyAdded) {
      CacheEntry entry = _partition.entryMap.remove(target);
      if (entry != null) {
        entry.dispose();
      }
      _partition._removeIfSource(target);
    }
    // Notify controller.
    _partition.onResultInvalidated
        .add(new InvalidatedResult(this, descriptor, thisData.value));
  }

  /**
   * Invalidates all the results of this entry, with propagation.
   */
  void _invalidateAll() {
    List<ResultDescriptor> results = _resultMap.keys.toList();
    for (ResultDescriptor result in results) {
      _invalidate(nextInvalidateId++, result, null, 0);
    }
  }

  /**
   * Invalidate results that depend on [thisData].
   */
  void _invalidateDependentResults(
      int id, ResultData thisData, Delta delta, int level) {
    List<TargetedResult> dependentResults = thisData.dependentResults.toList();
    for (TargetedResult dependentResult in dependentResults) {
      CacheEntry entry = _partition.get(dependentResult.target);
      if (entry != null) {
        entry._invalidate(id, dependentResult.result, delta, level);
      }
    }
  }

  /**
   * Set the [dependedOn] on which this result depends.
   */
  void _setDependedOnResults(ResultData thisData, TargetedResult thisResult,
      List<TargetedResult> dependedOn) {
    thisData.dependedOnResults.forEach((TargetedResult dependedOnResult) {
      ResultData data = _partition._getDataFor(dependedOnResult);
      if (data != null) {
        data.dependentResults.remove(thisResult);
      }
    });
    thisData.dependedOnResults = dependedOn;
    thisData.dependedOnResults.forEach((TargetedResult dependedOnResult) {
      ResultData data = _partition._getDataFor(dependedOnResult);
      if (data != null) {
        data.dependentResults.add(thisResult);
      }
    });
  }

  /**
   * Set states of the given and dependent results to [CacheState.ERROR] and
   * their values to the corresponding default values
   */
  void _setErrorState(ResultDescriptor descriptor, CaughtException exception) {
    ResultData thisData = getResultData(descriptor);
    // Set the error state.
    _exception = exception;
    thisData.state = CacheState.ERROR;
    thisData.value = descriptor.defaultValue;
    // Propagate the error state.
    thisData.dependentResults.forEach((TargetedResult dependentResult) {
      CacheEntry entry = _partition.get(dependentResult.target);
      entry._setErrorState(dependentResult.result, exception);
    });
  }

  /**
   * Set the value of the flag with the given [index] to the given [value].
   */
  void _setFlag(int index, bool value) {
    _flags = BooleanArray.set(_flags, index, value);
  }

  /**
   * If the state of the value described by the given [descriptor] is changing
   * from ERROR to anything else, capture the information. This is an attempt to
   * discover the underlying cause of a long-standing bug.
   */
  void _validateStateChange(ResultDescriptor descriptor, CacheState newState) {
    // TODO(brianwilkerson) Decide whether we still want to capture this data.
//    if (descriptor != CONTENT) {
//      return;
//    }
//    ResultData data = resultMap[CONTENT];
//    if (data != null && data.state == CacheState.ERROR) {
//      String message =
//          'contentState changing from ${data.state} to $newState';
//      InstrumentationBuilder builder =
//          Instrumentation.builder2('CacheEntry-validateStateChange');
//      builder.data3('message', message);
//      //builder.data('source', source.getFullName());
//      builder.record(new CaughtException(new AnalysisException(message), null));
//      builder.log();
//    }
  }

  /**
   * Write a textual representation of this entry to the given [buffer]. The
   * result should only be used for debugging purposes.
   */
  void _writeOn(StringBuffer buffer) {
    buffer.write('time = ');
    buffer.write(modificationTime);
    List<ResultDescriptor> results = _resultMap.keys.toList();
    results.sort((ResultDescriptor first, ResultDescriptor second) =>
        first.toString().compareTo(second.toString()));
    for (ResultDescriptor result in results) {
      ResultData data = _resultMap[result];
      buffer.write('; ');
      buffer.write(result.toString());
      buffer.write(' = ');
      buffer.write(data.state);
    }
  }
}

/**
 * An object that controls flushing of analysis results from the cache.
 */
class CacheFlushManager<T> {
  final IsPriorityAnalysisTarget isPriorityAnalysisTarget;
  final ResultCachingPolicy<T> policy;
  final int maxActiveSize;
  final int maxIdleSize;

  /**
   * A map of the stored [TargetedResult] to their sizes.
   */
  final HashMap<TargetedResult, int> resultSizeMap =
      new HashMap<TargetedResult, int>();

  /**
   * A linked set containing the most recently accessed results with the most
   * recently used at the end of the list. When more results are added than the
   * maximum size allowed then the least recently used results will be flushed
   * from the cache.
   */
  final LinkedHashSet<TargetedResult> recentlyUsed =
      new LinkedHashSet<TargetedResult>();

  /**
   * The current size of stored results.
   */
  int currentSize = 0;

  /**
   * The current maximum cache size.
   */
  int maxSize;

  CacheFlushManager(
      ResultCachingPolicy<T> policy, this.isPriorityAnalysisTarget)
      : policy = policy,
        maxActiveSize = policy.maxActiveSize,
        maxIdleSize = policy.maxIdleSize,
        maxSize = policy.maxIdleSize;

  /**
   * If [currentSize] is already less than [maxSize], returns an empty list.
   * Otherwise returns [TargetedResult]s to flush from the cache to make
   * [currentSize] less or equal to [maxSize].
   *
   * Results for priority files are never flushed, so this method might leave
   * [currentSize] greater than [maxSize].
   */
  List<TargetedResult> flushToSize() {
    // If still under the cap, done.
    if (currentSize <= maxSize) {
      return TargetedResult.EMPTY_LIST;
    }
    // Flush results until we are under the cap.
    List<TargetedResult> resultsToFlush = <TargetedResult>[];
    for (TargetedResult result in recentlyUsed) {
      if (isPriorityAnalysisTarget(result.target)) {
        continue;
      }
      resultsToFlush.add(result);
      int size = resultSizeMap.remove(result);
      assert(size != null);
      currentSize -= size;
      if (currentSize <= maxSize) {
        break;
      }
    }
    recentlyUsed.removeAll(resultsToFlush);
    return resultsToFlush;
  }

  /**
   * Notifies this manager that the corresponding analysis context is active.
   */
  void madeActive() {
    maxSize = maxActiveSize;
  }

  /**
   * Notifies this manager that the corresponding analysis context is idle.
   * Returns [TargetedResult]s that should be flushed from the cache.
   */
  List<TargetedResult> madeIdle() {
    maxSize = maxIdleSize;
    return flushToSize();
  }

  /**
   * Records that the given [result] was just read from the cache.
   */
  void resultAccessed(TargetedResult result) {
    if (recentlyUsed.remove(result)) {
      recentlyUsed.add(result);
    }
  }

  /**
   * Records that the given [newResult] and [newValue] were stored to the cache.
   * Returns [TargetedResult]s that should be flushed from the cache.
   */
  List<TargetedResult> resultStored(TargetedResult newResult, T newValue) {
    if (!recentlyUsed.remove(newResult)) {
      int size = policy.measure(newValue);
      resultSizeMap[newResult] = size;
      currentSize += size;
    }
    recentlyUsed.add(newResult);
    return flushToSize();
  }

  /**
   * Records that the given [target] was just removed from to the cache.
   */
  void targetRemoved(AnalysisTarget target) {
    List<TargetedResult> resultsToRemove = <TargetedResult>[];
    for (TargetedResult result in recentlyUsed) {
      if (result.target == target) {
        resultsToRemove.add(result);
        int size = resultSizeMap.remove(result);
        assert(size != null);
        currentSize -= size;
      }
    }
    recentlyUsed.removeAll(resultsToRemove);
  }
}

/**
 * A single partition in an LRU cache of information related to analysis.
 */
abstract class CachePartition {
  /**
   * The context that owns this partition. Multiple contexts can reference a
   * partition, but only one context can own it.
   */
  final InternalAnalysisContext context;

  /**
   * A table mapping caching policies to the cache flush managers.
   */
  final HashMap<ResultCachingPolicy, CacheFlushManager> _flushManagerMap =
      new HashMap<ResultCachingPolicy, CacheFlushManager>();

  /**
   * The [StreamController] reporting [InvalidatedResult]s.
   */
  final ReentrantSynchronousStream<InvalidatedResult> onResultInvalidated =
      new ReentrantSynchronousStream<InvalidatedResult>();

  /**
   * A table mapping the targets belonging to this partition to the information
   * known about those targets.
   */
  final HashMap<AnalysisTarget, CacheEntry> entryMap =
      new HashMap<AnalysisTarget, CacheEntry>();

  /**
   * A set of the [Source] targets.
   */
  final HashSet<Source> sources = new HashSet<Source>();

  /**
   * A table mapping full paths to lists of [Source]s with these full paths.
   */
  final Map<String, List<Source>> pathToSource = <String, List<Source>>{};

  /**
   * Initialize a newly created cache partition, belonging to the given
   * [context].
   */
  CachePartition(this.context);

  /**
   * Notifies the partition that the client is going to stop using it.
   */
  void dispose() {
    for (CacheEntry entry in entryMap.values) {
      entry.dispose();
    }
    entryMap.clear();
    sources.clear();
    pathToSource.clear();
  }

  /**
   * Return the entry associated with the given [target].
   */
  CacheEntry get(AnalysisTarget target) => entryMap[target];

  /**
   * Return [Source]s whose full path is equal to the given [path].
   * Maybe empty, but not `null`.
   */
  List<Source> getSourcesWithFullName(String path) {
    List<Source> sources = pathToSource[path];
    return sources != null ? sources : Source.EMPTY_LIST;
  }

  /**
   * Return `true` if this partition is responsible for the given [target].
   */
  bool isResponsibleFor(AnalysisTarget target);

  /**
   * Return an iterator returning all of the map entries mapping targets to
   * cache entries.
   */
  MapIterator<AnalysisTarget, CacheEntry> iterator() =>
      new SingleMapIterator<AnalysisTarget, CacheEntry>(entryMap);

  /**
   * Puts the given [entry] into the partition.
   */
  void put(CacheEntry entry) {
    AnalysisTarget target = entry.target;
    if (entry._partition != null) {
      throw new StateError(
          'The entry for $target is already in ${entry._partition}');
    }
    entry._partition = this;
    entry.fixExceptionState();
    entryMap[target] = entry;
    _addIfSource(target);
  }

  /**
   * Remove all information related to the given [target] from this partition.
   * Return the entry associated with the target, or `null` if there was cache
   * entry for the target.
   */
  CacheEntry remove(AnalysisTarget target) {
    for (CacheFlushManager flushManager in _flushManagerMap.values) {
      flushManager.targetRemoved(target);
    }
    CacheEntry entry = entryMap.remove(target);
    if (entry != null) {
      entry._invalidateAll();
    }
    _removeIfSource(target);
    return entry;
  }

  /**
   * Records that a value of the result described by the given [descriptor]
   * for the given [target] was just read from the cache.
   */
  void resultAccessed(AnalysisTarget target, ResultDescriptor descriptor) {
    CacheFlushManager flushManager = _getFlushManager(descriptor);
    TargetedResult result = new TargetedResult(target, descriptor);
    flushManager.resultAccessed(result);
  }

  /**
   * Records that the given [result] was just stored into the cache.
   */
  void resultStored(TargetedResult result, Object value) {
    CacheFlushManager flushManager = _getFlushManager(result.result);
    List<TargetedResult> resultsToFlush =
        flushManager.resultStored(result, value);
    for (TargetedResult result in resultsToFlush) {
      CacheEntry entry = get(result.target);
      if (entry != null) {
        ResultData data = entry._resultMap[result.result];
        if (data != null) {
          data.flush();
        }
      }
    }
  }

  /**
   * Return the number of targets that are mapped to cache entries.
   */
  int size() => entryMap.length;

  /**
   * If the given [target] is a [Source], adds it to [sources].
   */
  void _addIfSource(AnalysisTarget target) {
    if (target is Source) {
      sources.add(target);
      String fullName = target.fullName;
      pathToSource.putIfAbsent(fullName, () => <Source>[]).add(target);
    }
  }

  ResultData _getDataFor(TargetedResult result) {
    CacheEntry entry = context.analysisCache.get(result.target);
    return entry != null ? entry._resultMap[result.result] : null;
  }

  /**
   * Return the [CacheFlushManager] for the given [descriptor], not `null`.
   */
  CacheFlushManager _getFlushManager(ResultDescriptor descriptor) {
    ResultCachingPolicy policy = descriptor.cachingPolicy;
    if (identical(policy, DEFAULT_CACHING_POLICY)) {
      return UnlimitedCacheFlushManager.INSTANCE;
    }
    CacheFlushManager manager = _flushManagerMap[policy];
    if (manager == null) {
      manager = new CacheFlushManager(policy, _isPriorityAnalysisTarget);
      _flushManagerMap[policy] = manager;
    }
    return manager;
  }

  bool _isPriorityAnalysisTarget(AnalysisTarget target) {
    return context.priorityTargets.contains(target);
  }

  /**
   * If the given [target] is a [Source], remove it from the list of [sources].
   */
  void _removeIfSource(AnalysisTarget target) {
    if (target is Source) {
      sources.remove(target);
      String path = target.fullName;
      List<Source> pathSources = pathToSource[path];
      if (pathSources != null) {
        pathSources.remove(target);
        if (pathSources.isEmpty) {
          pathToSource.remove(path);
        }
      }
    }
  }
}

/**
 * The description for a change.
 */
class Delta {
  final Source source;

  Delta(this.source);

  /**
   * Check whether this delta affects the result described by the given
   * [descriptor] and [target].
   */
  DeltaResult validate(InternalAnalysisContext context, AnalysisTarget target,
      ResultDescriptor descriptor) {
    return DeltaResult.INVALIDATE;
  }
}

/**
 * The possible results of validating analysis results against a [Delta].
 */
enum DeltaResult {
  /**
   * Invalidate this result and continue visiting dependent results
   * with this [Delta].
   */
  INVALIDATE,

  /**
   * Invalidate this result and stop using this [Delta], so unconditionally
   * invalidate all the dependent results.
   */
  INVALIDATE_NO_DELTA,

  /**
   * Keep this result and continue validating dependent results
   * with this [Delta].
   */
  KEEP_CONTINUE,

  /**
   * Keep this result and stop visiting results that depend on this one.
   */
  STOP
}

/**
 * [InvalidatedResult] describes an invalidated result.
 */
class InvalidatedResult {
  /**
   * The target in which the result was invalidated.
   */
  final CacheEntry entry;

  /**
   * The descriptor of the result which was invalidated.
   */
  final ResultDescriptor descriptor;

  /**
   * The value of the result which was invalidated.
   */
  final Object value;

  InvalidatedResult(this.entry, this.descriptor, this.value);

  @override
  String toString() => '$descriptor of ${entry.target}';
}

/**
 * A Stream-like interface, which broadcasts events synchronously.
 * If a second event is fired while delivering a first event, then the second
 * event will be delivered first, and then delivering of the first will be
 * continued.
 */
class ReentrantSynchronousStream<T> {
  final List<Function> listeners = <Function>[];

  /**
   * Send the given [event] to the stream.
   */
  void add(T event) {
    List<Function> listeners = this.listeners.toList();
    for (Function listener in listeners) {
      listener(event);
    }
  }

  /**
   * Listen for the events in this stream.
   * Note that if the [listener] fires a new event, then the [listener] will be
   * invoked again before returning from the [add] invocation.
   */
  ReentrantSynchronousStreamSubscription<T> listen(void listener(T event)) {
    listeners.add(listener);
    return new ReentrantSynchronousStreamSubscription<T>(this, listener);
  }
}

/**
 * A subscription on events from a [ReentrantSynchronousStream].
 */
class ReentrantSynchronousStreamSubscription<T> {
  final ReentrantSynchronousStream<T> _stream;
  final Function _listener;

  ReentrantSynchronousStreamSubscription(this._stream, this._listener);

  /**
   * Cancels this subscription.
   * It will no longer receive events.
   */
  void cancel() {
    _stream.listeners.remove(_listener);
  }
}

/**
 * The data about a single analysis result that is stored in a [CacheEntry].
 */
// TODO(brianwilkerson) Consider making this a generic class so that the value
// can be typed.
class ResultData {
  /**
   * The [ResultDescriptor] this result is for.
   */
  final ResultDescriptor descriptor;

  /**
   * The state of the cached value.
   */
  CacheState state;

  /**
   * The value being cached, or the default value for the result if there is no
   * value (for example, when the [state] is [CacheState.INVALID]).
   */
  Object value;

  /**
   * The identifier of the invalidation process that most recently checked
   * this value. If it is the same as the current invalidation identifier,
   * then there is no reason to check it (and its subtree again).
   */
  int invalidateId = -1;

  /**
   * A list of the results on which this result depends.
   */
  List<TargetedResult> dependedOnResults = <TargetedResult>[];

  /**
   * A list of the results that depend on this result.
   */
  Set<TargetedResult> dependentResults = new Set<TargetedResult>();

  /**
   * Initialize a newly created result holder to represent the value of data
   * described by the given [descriptor].
   */
  ResultData(this.descriptor) {
    state = CacheState.INVALID;
    value = descriptor.defaultValue;
  }

  /**
   * Flush this value.
   */
  void flush() {
    state = CacheState.FLUSHED;
    value = descriptor.defaultValue;
  }
}

/**
 * A cache partition that contains all of the targets in the SDK.
 */
class SdkCachePartition extends CachePartition {
  /**
   * Initialize a newly created cache partition, belonging to the given
   * [context].
   */
  SdkCachePartition(InternalAnalysisContext context) : super(context);

  @override
  bool isResponsibleFor(AnalysisTarget target) {
    if (target is AnalysisContextTarget) {
      return true;
    }
    Source source = target.source;
    return source != null && source.isInSystemLibrary;
  }
}

/**
 * A cache partition that contains all targets not contained in other partitions.
 */
class UniversalCachePartition extends CachePartition {
  /**
   * Initialize a newly created cache partition, belonging to the given
   * [context].
   */
  UniversalCachePartition(InternalAnalysisContext context) : super(context);

  @override
  bool isResponsibleFor(AnalysisTarget target) => true;
}

/**
 * [CacheFlushManager] that does nothing, results are never flushed.
 */
class UnlimitedCacheFlushManager extends CacheFlushManager {
  static final CacheFlushManager INSTANCE = new UnlimitedCacheFlushManager();

  UnlimitedCacheFlushManager() : super(DEFAULT_CACHING_POLICY, (_) => false);

  @override
  void resultAccessed(TargetedResult result) {}

  @override
  List<TargetedResult> resultStored(TargetedResult newResult, newValue) {
    return TargetedResult.EMPTY_LIST;
  }

  @override
  void targetRemoved(AnalysisTarget target) {}
}
