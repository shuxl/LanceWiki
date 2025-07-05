以下是 Conda 常用命令的总结，涵盖环境管理、包管理、配置优化等核心操作，适用于 Linux/macOS/Windows 系统：


# 1 **环境管理**
• 查看所有环境  

  ```bash
  conda env list
  # 或
  conda info --envs
  ```
• 创建新环境（指定 Python 版本或包）  

  ```bash
  conda create -n env_name python=3.9 numpy pandas
  ```
• 激活/退出环境  

  ```bash
  conda activate env_name    # 激活
  conda deactivate           # 退出
  ```
  *注：Linux/macOS 可能需要用 `source activate env_name`。*
• 删除环境  

  ```bash
  conda remove -n env_name --all
  ```
• 复制环境  

  ```bash
  conda create --name new_env --clone old_env
  ```

+ mac默认环境
你的 .zshrc 末尾改成这样：
```
# <<< conda initialize <<<

# 激活默认 conda 环境
conda activate myenv
```

注意不要写在 # >>> conda initialize >>> 之间，这个区域会被 conda init 自动覆盖。

完成后执行：
```
source ~/.zshrc
```

---

# 2 **包管理**
• 查看已安装包  

  ```bash
  conda list
  ```
• 安装/卸载包  

  ```bash
  conda install package_name      # 当前环境安装
  conda remove package_name       # 卸载
  conda install -n env_name package_name  # 指定环境安装
  ```
• 搜索包（支持指定源如 `bioconda`）  

  ```bash
  conda search package_name -c bioconda
  ```
• 更新包或 Conda 自身  

  ```bash
  conda update package_name
  conda update conda
  ```

---

# 3 ** 配置与镜像优化**
• 添加清华镜像源（加速下载）  

  ```bash
  conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
  conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
  conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/
  conda config --set show_channel_urls yes
  ```
• 查看当前镜像配置  

  ```bash
  conda config --show channels
  ```

---

# 4 **环境迁移与共享**
• 导出环境配置（生成 `environment.yaml`）  

  ```bash
  conda env export > environment.yaml
  ```
• 从文件重建环境  

  ```bash
  conda env create -f environment.yaml
  ```

---

# 5 **其他实用命令**
• 清理缓存  

  ```bash
  conda clean --all
  ```
• 查看 Conda 版本  

  ```bash
  conda --version
  ```

---

# 6 **常见场景示例**
• 创建 TensorFlow 环境  

  ```bash
  conda create -n tf_env tensorflow-gpu=2.6.0
  conda activate tf_env
  ```
• 安装 R 语言环境  

  ```bash
  conda create -n r_env r=4.0 -c conda-forge
  ```

---

通过以上命令，可以高效管理 Python/R 等多语言环境及依赖包。如需更详细的配置（如 ARM 架构支持），可参考各平台文档。