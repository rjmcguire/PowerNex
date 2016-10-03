module IO.FS.DirectoryNode;

import IO.FS;
import IO.Log;

class DirectoryNode : Node {
public:
	this(NodePermissions permission) {
		super(permission);
	}

	Node FindNode(string path) {
		return FindNode(path, true);
	}

	MountPointNode Mount(DirectoryNode node, FSRoot fs) {
		if (node.Parent != this) {
			log.Error("Tried to run Mount on ", node.Name, " but it doesn't belong to ", name, "! Redirecting");
			node.Parent.Mount(node, fs);
		}
		MountPointNode mount = new MountPointNode(node, fs);
		node.Parent = null;
		node.Root = null;
		mount.Root = root;
		mount.Parent = this;
		mount.RootMount.Parent = this;
		return mount;
	}

	DirectoryNode Unmount(MountPointNode node) {
		if (node.Parent != this) {
			log.Error("Tried to run Unmount on ", node.Name, " but it doesn't belong to ", name, "! Redirecting");
			node.Parent.Unmount(node);
		}
		node.RootMount.Parent = null;
		node.Parent = null;
		node.Root = null;
		DirectoryNode dir = node.OldNode;
		dir.root = root;
		dir.Parent = this;
		node.destroy;
		return dir;
	}

	@property Node[] Nodes() {
		return nodes[0 .. nodeCount];
	}

	DirectoryNode SetParentNoUpdate(DirectoryNode node) {
		if (!node)
			parent = oldParent;
		else {
			oldParent = parent;
			parent = node;
		}
		return parent;
	}

package:

	Node Add(Node node) {
		return add(node);
	}

	Node Remove(Node node) {
		return remove(node);
	}

	Node FindNode(string path, bool firstTime) {
		import KMain : rootFS;

		log.Info("CUR: ", Name, " FindNode: ", path, " firstTime: ", firstTime);
		if (!path.length)
			return this;

		if (path[0] == '/') {
			if (firstTime)
				return rootFS.Root.FindNode(path[1 .. $], false); //root.Root.FindNode(path[1 .. $], false);

			while (path.length && path[0] == '/')
				path = path[1 .. $];
			if (!path.length)
				return this;
		}

		if (path.length > 1 && path[0 .. 2] == "..") {
			DirectoryNode p = parent;
			if (!p)
				p = root.Root;
			return p.FindNode(path[2 .. $], false);
		} else if (path.length > 1 && path[0 .. 2] == "./")
			path = path[2 .. $];

		if (!path.length || path.length == 1 && path[0] == '.')
			return this;

		ulong end = 0;

		while (end < path.length && path[end] != '/')
			end++;

		foreach (node; nodes[0 .. nodeCount]) {
			log.Info("\t cur Name: ", node.Name);
			if (node.Name == path[0 .. end]) {
				auto n = node;
				while (true) {
					if (auto hardlink = cast(HardLinkNode)n)
						n = hardlink.Target;
					else if (auto softlink = cast(SoftLinkNode)n)
						n = softlink.Target;
					else
						break;
				}

				if (end == path.length)
					return n;

				if (auto mp = cast(MountPointNode)node)
					return mp.RootMount.Root.FindNode(path[end + 1 .. $], false);
				if (auto dir = cast(DirectoryNode)node)
					return dir.FindNode(path[end + 1 .. $], false);

				return null;
			}
		}

		return null;
	}

protected:
	DirectoryNode oldParent;
	Node[] nodes;
	ulong nodeCount;

	Node add(Node node) {
		if (node.Parent == this)
			return node;
		log.Info("DirectoryNode ", ID, " Add: ", node.ID, "(", cast(void*)node, ")");
		if (nodes.length == nodeCount) {
			nodes.length += 8;
			for (ulong i = nodeCount; i < nodes.length; i++)
				nodes[i] = null;
		}

		nodes[nodeCount++] = node;
		return node;
	}

	Node remove(Node node) {
		if (node.Parent != this)
			return node;
		log.Info("DirectoryNode ", ID, " Remove: ", node.ID, "(", cast(void*)node, ")");
		ulong i = 0;
		while (i < nodeCount && nodes[i] != node)
			i++;
		if (i >= nodeCount)
			return node;

		for (; i < nodeCount; i++)
			nodes[i] = nodes[i + 1];
		nodeCount--;
		return node;
	}
}
