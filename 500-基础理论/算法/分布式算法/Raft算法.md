+ [视频理解](https://www.bilibili.com/video/BV1stu9zKEDh?spm_id_from=333.788.player.player_end_recommend&vd_source=dc9fbc83caec08fa4ea393d6bb5174b5)
# 1 背景与目标

分布式系统中，如果多个节点要对同一份数据或状态达成一致，需要**一致性算法**。
Raft 是 2013 年 Diego Ongaro 和 John Ousterhout 提出的**易理解、易实现**的共识算法，用于构建**强一致性**的分布式系统。
它的目标是：
- 容忍部分节点宕机或网络分区（只要多数节点可用）
- 保证数据线性一致（Linearizability）
- 尽可能让开发者和工程师更容易实现和调试

Raft 主要分为三个子问题：
1. **Leader 选举**
2. **日志复制**
3. **安全性保证**

---

# 2 节点角色与状态机

每个节点在任何时刻都处于三种状态之一：
- **Follower（跟随者）**
    - 被动状态，只响应来自 Leader 或 Candidate 的 RPC
- **Candidate（候选人）**
    - 选举阶段的中间状态
- **Leader（领导者）**
    - 唯一主动处理客户端请求的节点

状态转换规则：

```
Follower  →  Candidate  →  Leader
   ↑                        ↓
   ←--------（失去 Leader，超时，重新选举）-------
```

---

# 3 时间概念

Raft 引入了**Term（任期）**：
- 每次选举成功 → 任期号 +1
- 每个 RPC（投票或日志复制）都携带任期号
- 任期号用于检测过期的 Leader 或 Candidate

三个关键的定时器：
1. **选举超时（Election Timeout）**
    - Follower 在此时间内没收到 Leader 心跳，就发起选举
    - 通常是随机范围（如 150–300ms）防止冲突
2. **心跳间隔（Heartbeat Interval）**
    - Leader 定期发送 AppendEntries（即心跳）
3. **RPC 超时**
    - 处理网络延迟或失败
    

---

# 4 Leader 选举过程

1. Follower 在**选举超时**后，变为 Candidate
2. Candidate：
    - 任期号 +1
    - 给自己投一票
    - 发送 **RequestVote RPC** 给所有节点
3. 如果：
    - 获得多数票 → 成为 Leader
    - 收到任期号更大的节点消息 → 退回 Follower
    - 选举超时未成功 → 再次发起选举（任期号再 +1）
  
投票规则：
- 每个节点每个任期最多投一次票
- 只有候选人日志至少与自己一样新，才会投票（防止落后节点当选）

---

# 5 日志复制机制

Leader 负责：
1. 接收客户端请求，作为新日志条目（Log Entry）
2. 将日志条目附带**前一条日志的索引和任期号**，通过 AppendEntries RPC 发给所有 Follower
3. 等待多数节点确认写入（复制成功）
4. 更新 commitIndex（提交索引）
5. 通知各节点将已提交日志应用到状态机

Follower 处理：
- 如果日志与本地不匹配，回滚冲突部分再追加
- 发送确认给 Leader

---

# 6 日志冲突处理

Raft 要求：
- 同一日志索引位置，term 必须一致，否则冲突
- AppendEntries 时携带 (prevLogIndex, prevLogTerm)：
    - 如果 Follower 不匹配 → 回退日志直到找到匹配位置
    - 再追加 Leader 的新日志
- 这样保证所有已提交日志最终一致

---

# 7 提交与安全性

提交条件：
- Leader 收到多数节点对某条日志的确认
- 该日志所在的 term 是当前 Leader 的任期
  
安全性保证：
1. **Leader Completeness**
    - 当某条日志提交后，未来的 Leader 必然包含它
2. **State Machine Safety**
    - 所有节点应用到状态机的日志顺序和内容完全一致

---

# 8 容错特性

- 可容忍最多 ⌊(N-1)/2⌋ 节点故障（N 为总节点数）
- 即 5 节点集群可容忍 2 节点宕机
- 依赖**多数派原则**来确保一致性

---

# 9 Raft 的 RPC 类型

1. **RequestVote RPC**
    - Candidate 发起投票请求
2. **AppendEntries RPC**
    - Leader 发送心跳或日志
3. **InstallSnapshot RPC**
    - 当日志太长或 Follower 太落后时，发送快照
    

---

# 10 Raft 优势
- **比 Paxos 更易理解**（主要通过引入 Leader 简化）
- 日志复制和选举逻辑清晰
- 广泛用于 etcd、Consul、TiKV 等

---

# 11 简化版流程图（文字描述）

```
[Follower]
  ↓ (选举超时)
[Candidate] --(多数票)--> [Leader]
  ↑                         |
  |                         | (心跳)
  +----(失去Leader信号)-----+
```

Leader 周期：

```
客户端请求 → Leader 写本地日志 → 复制到 Follower → 多数确认 → 提交并返回结果
```
