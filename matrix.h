#ifndef GRAPHICAL_MATRIX_H
#define GRAPHICAL_MATRIX_H
#include <QObject>

template <typename T>
QList<T> operator*(const QList<T>& lhs_vector, float scalar) {
	auto size = lhs_vector.size();

	QList<T> result(size);

	for (qsizetype i = 0; i < size; i++) {
		result[i] = scalar * lhs_vector[i];
	}

	return result;
}

template <typename T>
QList<T> operator*(float scalar, const QList<T>& rhs_vector) {
	auto size = rhs_vector.size();
	QList<T> result(size);

	for (qsizetype i = 0; i < size; i++) {
		result[i] = scalar * rhs_vector[i];
	}

	return result;
}

template <typename T>
QList<T> operator+(const QList<T>& lhs_vector, const QList<T>& rhs_vector) {
	auto size = lhs_vector.size();
	if (rhs_vector.size() != size) {
		throw std::invalid_argument("Size mismatch");
	}

	QList<T> result(size);

	for (qsizetype i = 0; i < size; ++i) {
		result[i] = lhs_vector[i] + rhs_vector[i];
	}

	return result;
}

template <typename T>
QList<T> operator-(const QList<T>& lhs_vector, const QList<T>& rhs_vector) {
	auto size = lhs_vector.size();
	if (rhs_vector.size() != size) {
		throw std::invalid_argument("Size mismatch");
	}

	QList<T> result(size);

	for (qsizetype i = 0; i < size; ++i) {
		result[i] = lhs_vector[i] - rhs_vector[i];
	}

	return result;
}

template <typename T>
QList<T> operator/(const QList<T>& lhs_vector, const float scalar) {
	return 1.f / scalar * lhs_vector;
}

template <typename T>
struct g_matrix {
	explicit g_matrix();
	explicit g_matrix(const QList<QList<T>>& data);
	explicit g_matrix(qsizetype size);

	[[nodiscard]] bool isSquare() const;
	[[nodiscard]] g_matrix inverse() const;
	[[nodiscard]] g_matrix transpose() const;

	[[nodiscard]] qint64 rows() const;
	[[nodiscard]] qint64 columns() const;

	[[nodiscard]] bool isEmpty() const;

	[[nodiscard]] T& at(qint64 row, qint64 column);
	[[nodiscard]] T at(qint64 row, qint64 column) const;

	[[nodiscard]] bool canMultiply(const g_matrix& other) const;
	[[nodiscard]] bool canMultiply(const QList<T>& other) const;

	g_matrix operator*(const g_matrix& rhs_matrix); // mult by another matrix (throws if the input is invalid)
	QList<T> operator*(const QList<T>& rhs_column); // mult by column vector

	QList<QList<T>> _data;
};

template <typename T>
g_matrix<T>::g_matrix() = default;

template <typename T>
g_matrix<T>::g_matrix(const QList<QList<T>>& data) : _data(data) {}

template <typename T>
g_matrix<T>::g_matrix(qsizetype size) {
	_data = QList<QList<T>>(size);
}

template <typename T>
bool g_matrix<T>::isSquare() const {
	auto size = _data.size();
	for (const auto& row : std::as_const(_data)) {
		if (row.size() != size) return false;
	}

	return true;
}

template <typename T>
g_matrix<T> g_matrix<T>::inverse() const {
	if (!isSquare()) throw std::invalid_argument("Matrix needs to be square!");
	auto size = _data.size();

	g_matrix result(size);

	for (qsizetype i = 0; i < size; ++i) {
		result._data[i] = QList<T>(size);
		for (qsizetype j = 0; j < size; ++j) {
			result._data[i][j] = i == j ? static_cast<T>(1) : static_cast<T>(0);
		}
	}

	g_matrix temp(size);
	for (qsizetype i = 0; i < size; ++i) {
		QList<T> row(size);
		for (qsizetype j = 0; j < size; ++j) row[j] = static_cast<T>(_data[i][j]);

		temp._data[i] = row;
	}

	for (qsizetype i = 0; i < size; ++i) {
		for (qsizetype i2 = i; i2 < size && temp._data[i][i] == 0; i2++) {
			temp._data[i] = temp._data[i] + temp._data[i2];
			result._data[i] = result._data[i] + result._data[i2];
		}

		for (qsizetype j2 = i; j2 < size && temp._data[i][i] == 0; j2++) {
			for (qsizetype i2 = 0; i2 < size; i2++) {
				temp._data[i2][i] = temp._data[i2][i] + temp._data[i2][j2];
				result._data[i2][i] = result._data[i2][i] + result._data[i2][j2];
			}
		}

		if (temp._data[i][i] == 0) throw std::invalid_argument("Matrix doesnt have inverse!");

		auto div = static_cast<T>(temp._data[i][i]);
		temp._data[i] = temp._data[i] / div;
		result._data[i] = result._data[i] / div;

		for (qsizetype i2 = 0; i2 < size; i2++) {
			if (i2 == i) continue;

			auto factor = temp._data[i2][i];
			temp._data[i2] = temp._data[i2] - factor * temp._data[i];
			result._data[i2] = result._data[i2] - factor * result._data[i];
		}
	}

	return result;
}

template <typename T>
g_matrix<T> g_matrix<T>::transpose() const {
	auto size = _data.at(0).size();
	g_matrix result(size);
	for (qsizetype i = 0; i < size; ++i) {
		QList<T> row(_data.size());
		for (qsizetype j = 0; j < _data.size(); ++j) row[j] = _data[j][i];

		result._data[i] = row;
	}

	return result;
}

template <typename T>
qint64 g_matrix<T>::rows() const {
	return _data.size();
}

template <typename T>
qint64 g_matrix<T>::columns() const {
	if (_data.isEmpty()) return 0;
	return _data[0].size();
}

template <typename T>
bool g_matrix<T>::isEmpty() const {
	return _data.isEmpty();
}

template <typename T>
T& g_matrix<T>::at(qint64 row, qint64 column) {
	return _data[row][column];
}

template <typename T>
T g_matrix<T>::at(qint64 row, qint64 column) const {
	return _data[row][column];
}

template <typename T>
bool g_matrix<T>::canMultiply(const g_matrix& other) const {
	return _data.at(0).size() == other._data.size();
}

template <typename T>
bool g_matrix<T>::canMultiply(const QList<T>& other) const {
	return _data.at(0).size() == other.size();
}

template <typename T>
g_matrix<T> g_matrix<T>::operator*(const g_matrix& rhs_matrix) {
	if (!canMultiply(rhs_matrix)) throw std::invalid_argument("Can't multiply matrix");
	auto size_data = _data.size();
	auto size_other = rhs_matrix._data.at(0).size();
	g_matrix result(size_data);
	for (qsizetype i = 0; i < size_data; ++i) {
		QList<T> row(size_other);
		for (qsizetype j = 0; j < size_other; ++j) {
			row[j] = static_cast<T>(0);
			for (qsizetype k = 0; k < rhs_matrix._data.size(); ++k) row[j] += _data[i][k] * rhs_matrix._data[k][j];
		}

		result._data[i] = row;
	}

	return result;
}

template <typename T>
QList<T> g_matrix<T>::operator*(const QList<T>& rhs_column) {
	if (!canMultiply(rhs_column)) throw std::invalid_argument("Can't multiply matrix");
	auto size_data = _data.size();
	QList<T> result(size_data);

	for (qsizetype i = 0; i < size_data; ++i) {
		result[i] = static_cast<T>(0);
		for (qsizetype j = 0; j < rhs_column.size(); ++j) result[i] += _data[i][j] * rhs_column[j];
	}

	return result;
}
#endif //GRAPHICAL_MATRIX_H
